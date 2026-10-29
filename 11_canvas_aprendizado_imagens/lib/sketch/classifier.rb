module Sketch
  # CNN didática em Ruby: convolução treinável, ReLU, average pooling e
  # saída sigmoide por classe. Backpropagation ajusta também os filtros.
  class Classifier
    ALGORITHM = 'cnn_v1'
    FILTERS = 6
    CONV_SIDE = 15
    POOL_SIDE = 5
    FEATURES = FILTERS * POOL_SIDE * POOL_SIDE
    THRESHOLD = 0.78
    MARGIN = 0.12
    NOVELTY_LIMIT = 0.20
    RATE = 0.12
    CONV_RATE = 0.015
    EPOCHS = 35
    EMPTY = '0' * 1024

    def initialize
      @random = Random.new(1107)
    end

    def predict(mask, model)
      return { status: 'unknown', label: nil, score: nil, matches: [], reason: 'Ainda não treinei a CNN. Informe o nome e treine este desenho.' } if model.fetch('labels').empty?
      features = forward(patches(mask), model).first
      ranked = model['labels'].each_index.map do |index|
        label = model['labels'][index]
        { label: label, score: sigmoid(dot(model['weights'][index], features) + model['bias'][index]).round(4),
          id: model.fetch('examples', []).reverse.find { |sample| sample['label'] == label }&.fetch('id', nil) }
      end.sort_by { |match| -match[:score] }
      best, runner_up = ranked
      recognized = best[:score] >= THRESHOLD && (runner_up.nil? || best[:score] - runner_up[:score] >= MARGIN) && familiar?(features, best[:label], model)
      { status: recognized ? 'recognized' : 'unknown', label: recognized ? best[:label] : nil,
        score: best[:score], matches: ranked.first(3),
        reason: recognized ? 'A CNN reconheceu os padrões deste desenho.' : 'Ainda não reconheço com segurança. Informe o nome e treine de novo.' }
    end

    def train(model, labeled_masks)
      model['conv'] ||= { 'kernels' => Array.new(FILTERS) { Array.new(9) { @random.rand * 0.8 - 0.4 } }, 'bias' => Array.new(FILTERS, 0.1) }
      labeled_masks.each do |label, _|
        next if model['labels'].include?(label)
        model['labels'] << label
        model['weights'] << Array.new(FEATURES) { @random.rand * 0.1 - 0.05 }
        model['bias'] << 0.0
      end
      samples = labeled_masks.map { |label, mask| [model['labels'].index(label), patches(mask)] }
      3.times { samples << [-1, patches(EMPTY)] }
      EPOCHS.times { samples.shuffle(random: @random).each { |index, input| step(model, index, input) } }
      model
    end

    private

    # Uma sigmoide pode ser confiante com uma classe ainda desconhecida.
    # Exige também proximidade nas características aprendidas pela própria CNN.
    def familiar?(features, label, model)
      references = model.fetch('examples', []).select { |sample| sample['label'] == label }.last(3)
      references.any? do |sample|
        reference = forward(patches(sample['mask']), model).first
        norm = reference.sum { |value| value * value }
        distance = features.each_index.sum { |i| (features[i] - reference[i])**2 }
        distance / [norm, 1e-8].max <= NOVELTY_LIMIT
      end
    end

    # Centraliza e ajusta a silhueta com proporção preservada. Não rotaciona.
    # A mesma transformação é aplicada ao treino e à identificação.
    def patches(mask)
      unless mask.is_a?(String) && mask.bytesize == 1024 && mask.match?(/\A[01]+\z/)
        raise ArgumentError, 'A silhueta precisa ter 32 × 32 pixels binários.'
      end
      positions = (0...1024).select { |i| mask.getbyte(i) == 49 }
      pixels = Array.new(1024, 0.0)
      unless positions.empty?
        xs, ys = positions.map { |i| i % 32 }, positions.map { |i| i / 32 }
        left, top = xs.min, ys.min
        width, height = xs.max - left + 1, ys.max - top + 1
        scale = 24.0 / [width, height].max
        w, h = [(width * scale).round, 1].max, [(height * scale).round, 1].max
        h.times do |y|
          w.times do |x|
            sx = left + ((x + 0.5) * width / w).floor.clamp(0, width - 1)
            sy = top + ((y + 0.5) * height / h).floor.clamp(0, height - 1)
            pixels[(y + (32 - h) / 2) * 32 + x + (32 - w) / 2] = mask.getbyte(sy * 32 + sx) == 49 ? 1.0 : 0.0
          end
        end
      end
      Array.new(CONV_SIDE * CONV_SIDE) do |i|
        base = (i / CONV_SIDE * 2) * 32 + i % CONV_SIDE * 2
        Array.new(9) { |k| pixels[base + k / 3 * 32 + k % 3] }
      end
    end

    def forward(input, model)
      activations = model['conv']['kernels'].each_with_index.map do |kernel, f|
        input.map { |patch| [dot(kernel, patch) + model['conv']['bias'][f], 0.0].max }
      end
      features = activations.flat_map do |map|
        Array.new(25) do |p|
          base = p / 5 * 3 * CONV_SIDE + p % 5 * 3
          9.times.sum { |k| map[base + k / 3 * CONV_SIDE + k % 3] } / 9.0
        end
      end
      [features, activations]
    end

    def step(model, target, input)
      features, activations = forward(input, model)
      gradient = Array.new(FEATURES, 0.0)
      model['labels'].each_index do |index|
        weights = model['weights'][index]
        error = sigmoid(dot(weights, features) + model['bias'][index]) - (index == target ? 1.0 : 0.0)
        FEATURES.times do |i|
          gradient[i] += error * weights[i]
          weights[i] -= RATE * (error * features[i] + 0.0001 * weights[i])
        end
        model['bias'][index] -= RATE * error
      end
      FILTERS.times do |f|
        kernel_gradient = Array.new(9, 0.0)
        bias_gradient = 0.0
        225.times do |i|
          next if activations[f][i] <= 0.0
          pool_index = i / CONV_SIDE / 3 * 5 + i % CONV_SIDE / 3
          delta = gradient[f * 25 + pool_index] / 9.0
          bias_gradient += delta
          9.times { |k| kernel_gradient[k] += delta * input[i][k] }
        end
        9.times { |k| model['conv']['kernels'][f][k] -= CONV_RATE * kernel_gradient[k].clamp(-5.0, 5.0) }
        model['conv']['bias'][f] -= CONV_RATE * bias_gradient.clamp(-5.0, 5.0)
      end
    end

    def dot(a, b)
      sum = 0.0
      a.size.times { |i| sum += a[i] * b[i] }
      sum
    end

    def sigmoid(value) = 1.0 / (1.0 + Math.exp(-value.clamp(-20.0, 20.0)))
  end
end
