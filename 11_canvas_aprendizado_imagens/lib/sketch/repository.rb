require 'json'
require 'digest'
require 'fileutils'
require 'time'
require 'chunky_png'
module Sketch
  class Repository
    LIMIT = 500
    REPLAY_PER_CLASS = 5
    def initialize(directory)
      @directory = directory.to_s
      FileUtils.mkdir_p(@directory)
    end

    def identify(pixels)
      prepared = Preprocessor.new.call(pixels)
      synchronized do |model|
        Classifier.new.predict(prepared.mask, model).merge(summary: summary_for(model), ink_pixels: prepared.ink_count)
      end
    end

    def teach(pixels, label)
      prepared = Preprocessor.new.call(pixels)
      label = normalize_label(label)
      synchronized do |model|
        id = Digest::SHA256.hexdigest(prepared.mask)
        examples = model['examples']
        existing = examples.find { |sample| sample['id'] == id }
        raise ArgumentError, 'O laboratório atingiu 500 exemplos. Use a base salva para continuar os estudos em uma versão ampliada.' if !existing && examples.size >= LIMIT
        previous_label = existing&.fetch('label')
        sample = { 'id' => id, 'label' => label, 'mask' => prepared.mask, 'updated_at' => Time.now.utc.iso8601 }
        existing ? existing.replace(sample) : examples << sample
        # Reaprende também as variações das classes anteriores.
        replay = examples.reject { |item| item['id'] == id }.group_by { |item| item['label'] }.flat_map do |_name, group|
          group.last(REPLAY_PER_CLASS).flat_map { |item| Preprocessor.new.variants_from_mask(item['mask']).map { |mask| [item['label'], mask] } }
        end
        batch = prepared.variants.map { |mask| [label, mask] } + replay
        # Uma correção não deve deixar a classe incorreta nos pesos.
        if previous_label && previous_label != label
          model.replace(blank_model.merge('examples' => examples))
          batch = examples.flat_map { |item| Preprocessor.new.variants_from_mask(item['mask']).map { |mask| [item['label'], mask] } }
        end
        Classifier.new.train(model, batch)
        save_png(id, prepared.pixels)
        save(model)
        {
          status: 'learned',
          label: label,
          corrected: previous_label && previous_label != label,
          variants: prepared.variants.size,
          epochs: Classifier::EPOCHS,
          training_presentations: prepared.variants.size * Classifier::EPOCHS,
          message: "Treinei a CNN com #{prepared.variants.size} versões deste desenho por #{Classifier::EPOCHS} épocas: maior, menor, esquerda, direita, cima e baixo, sem rotação.",
          summary: summary_for(model)
        }
      end
    end

    def summary = synchronized { |model| summary_for(model) }

    def pretrain
      prepared = StarterImages.new.samples.map { |sample| [sample[:label], Preprocessor.new.call(sample[:pixels])] }
      synchronized do |model|
        new_samples = prepared.reject do |_label, image|
          id = Digest::SHA256.hexdigest(image.mask)
          model['examples'].any? { |sample| sample['id'] == id }
        end
        raise ArgumentError, 'Não há espaço para a base inicial. O limite é de 500 exemplos.' if model['examples'].size + new_samples.size > LIMIT
        added = 0
        new_samples.each do |label, image|
          id = Digest::SHA256.hexdigest(image.mask)
          # Nunca substitui um rótulo que o usuário já ensinou.
          model['examples'] << { 'id' => id, 'label' => label, 'mask' => image.mask, 'updated_at' => Time.now.utc.iso8601, 'source' => 'starter' }
          save_png(id, image.pixels)
          added += 1
        end
        # Um único treino balanceado revisa os exemplos salvos e os novos.
        batch = model['examples'].group_by { |sample| sample['label'] }.flat_map do |_label, samples|
          samples.last(REPLAY_PER_CLASS).flat_map { |sample| Preprocessor.new.variants_from_mask(sample['mask']).map { |mask| [sample['label'], mask] } }
        end
        Classifier.new.train(model, batch)
        save(model)
        { status: 'pretrained', added: added, variants: prepared.first.last.variants.size, epochs: Classifier::EPOCHS,
          message: "Base inicial treinada: #{added} novos exemplos. Usei #{Preprocessor::TRAINING_VARIANTS.size} versões por imagem, durante #{Classifier::EPOCHS} épocas, sem rotação. Seus exemplos foram mantidos.",
          summary: summary_for(model) }
      end
    end

    def reset
      synchronized do |model|
        # Repetir o reset de um modelo vazio não apaga o último treino salvo.
        write_json(checkpoint_path, model) unless model['examples'].empty?
        empty = blank_model
        save(empty)
        { status: 'reset', message: 'Modelo limpo. Você pode ensinar novos desenhos ou treinar com os exemplos de teste.', summary: summary_for(empty) }
      end
    end

    def restore
      synchronized do |model|
        raise ArgumentError, 'Ainda não existe um treinamento anterior para restaurar.' unless File.file?(checkpoint_path)
        previous = JSON.parse(File.read(checkpoint_path))
        # Guarda também o treino ativo antes de substituí-lo.
        write_json(File.join(@directory, 'model.before-restore.json'), model) unless model['examples'].empty?
        save(previous)
        { status: 'restored', message: 'Treinamento anterior restaurado, com os mesmos pesos e exemplos.', summary: summary_for(previous) }
      end
    end

    def sample_path(id)
      return unless id.to_s.match?(/\A[0-9a-f]{64}\z/)
      synchronized do |model|
        path = File.join(@directory, 'images', "#{id}.png")
        path if model['examples'].any? { |sample| sample['id'] == id } && File.file?(path)
      end
    end

    private

    def checkpoint_path = File.join(@directory, 'model.before-reset.json')

    def write_json(path, payload)
      temporary = "#{path}.tmp"
      File.write(temporary, JSON.generate(payload))
      File.rename(temporary, path)
    end

    def normalize_label(label)
      value = label.to_s.unicode_normalize(:nfc).strip.downcase.gsub(/\s+/, ' ')
      value = value.sub(/\A(?:isso|isto) (?:é|e) (?:um |uma )?/, '')
      unless value.match?(/\A[\p{L}\p{N}][\p{L}\p{N} \-]{0,29}\z/u)
        raise ArgumentError, 'Dê um nome de até 30 caracteres, usando letras, números ou espaços.'
      end
      { 'triangulo' => 'triângulo', 'trinagulo' => 'triângulo', 'circulo' => 'círculo' }.fetch(value, value)
    end

    def synchronized
      File.open(File.join(@directory, 'model.lock'), 'a') do |lock|
        lock.flock(File::LOCK_EX)
        yield load_model
      ensure
        lock.flock(File::LOCK_UN)
      end
    end

    def load_model
      path = File.join(@directory, 'model.json')
      return blank_model unless File.exist?(path)
      data = JSON.parse(File.read(path))
      return data if data['algorithm'] == Classifier::ALGORITHM && data['labels'].is_a?(Array)
      FileUtils.cp(path, "#{path}.before-cnn.bak") unless File.exist?("#{path}.before-cnn.bak")
      migrate(data)
    end

    def blank_model
      {
        'format' => 3,
        'algorithm' => Classifier::ALGORITHM,
        'side' => Preprocessor::SIDE,
        'threshold' => Classifier::THRESHOLD,
        'margin' => Classifier::MARGIN,
        'labels' => [],
        'weights' => [],
        'bias' => [],
        'conv' => nil,
        'examples' => []
      }
    end

    def migrate(data)
      model = blank_model
      model['examples'] = Array(data['examples'])
      batch = model['examples'].flat_map do |sample|
        Preprocessor.new.variants_from_mask(sample['mask']).map { |mask| [sample['label'], mask] }
      end
      Classifier.new.train(model, batch) unless batch.empty?
      save(model)
      model
    end

    def save(model)
      payload = blank_model.merge(
        'labels' => model['labels'],
        'weights' => model['weights'],
        'bias' => model['bias'],
        'conv' => model['conv'],
        'examples' => model['examples']
      )
      write_json(File.join(@directory, 'model.json'), payload)
    end

    def save_png(id, pixels)
      directory = File.join(@directory, 'images')
      FileUtils.mkdir_p(directory)
      png = ChunkyPNG::Image.new(Preprocessor::INPUT, Preprocessor::INPUT)
      pixels.each_with_index { |v, i| png[i % Preprocessor::INPUT, i / Preprocessor::INPUT] = ChunkyPNG::Color.rgb(v, v, v) }
      temporary = File.join(directory, "#{id}.tmp.png")
      png.save(temporary)
      File.rename(temporary, File.join(directory, "#{id}.png"))
    end

    def summary_for(model)
      examples = model['examples']
      {
        count: examples.size,
        can_restore: File.file?(checkpoint_path),
        classes: examples.group_by { |sample| sample['label'] }.map { |label, group| { label: label, count: group.size } },
        examples: examples.reverse.map { |sample| { id: sample['id'], label: sample['label'], url: "/exemplos/#{sample['id']}" } }
      }
    end
  end
end
