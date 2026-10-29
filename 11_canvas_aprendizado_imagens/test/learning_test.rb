require 'minitest/autorun'
require 'json'
require 'tmpdir'
%w[preprocessor classifier starter_images repository].each { |file| require_relative "../lib/sketch/#{file}" }
require_relative 'raster_fixtures'

class LearningTest < Minitest::Test
  include RasterFixtures

  def test_no_prior_shapes_and_learning_from_the_users_label
    Dir.mktmpdir do |directory|
      repository = Sketch::Repository.new(directory)
      assert_equal 'unknown', repository.identify(square)[:status]
      assert_equal 0, repository.summary[:count]
      learned = repository.teach(square, 'Isso é um trinagulo')
      assert_equal 'triângulo', learned[:label]
      assert_equal 6, learned[:variants]
      assert_equal 35, learned[:epochs]
      assert_equal 210, learned[:training_presentations]
      prediction = repository.identify(square(left: 5, top: 7, side: 27))
      assert_equal 'recognized', prediction[:status]
      assert_equal 'triângulo', prediction[:label]
      assert_operator prediction[:score], :>=, Sketch::Classifier::THRESHOLD
      restored = Sketch::Repository.new(directory)
      assert_equal 'triângulo', restored.identify(square)[:label]
      assert_equal 1, restored.summary[:count]
      path = restored.sample_path(restored.summary[:examples].first[:id])
      assert_equal [64, 64], [ChunkyPNG::Image.from_file(path).width, ChunkyPNG::Image.from_file(path).height]
      model = JSON.parse(File.read(File.join(directory, 'model.json')))
      assert_equal 'cnn_v1', model['algorithm']
      assert_equal Sketch::Classifier::FEATURES, model['weights'].first.size
      assert_equal 6, model['conv']['kernels'].size
      assert_equal 9, model['conv']['kernels'].first.size
      assert_equal 1, model['bias'].size
    end
  end

  def test_unknown_new_shape_then_learning_a_second_class
    Dir.mktmpdir do |directory|
      repository = Sketch::Repository.new(directory)
      repository.teach(square, 'quadrado')
      assert_equal 'unknown', repository.identify(triangle)[:status]
      repository.teach(triangle, 'triângulo')
      assert_equal 'triângulo', repository.identify(triangle)[:label]
      assert_equal 'quadrado', repository.identify(square)[:label]
      assert_equal 2, repository.summary[:classes].size
    end
  end

  def test_correction_replaces_a_wrong_label_without_conflicting_duplicates
    Dir.mktmpdir do |directory|
      repository = Sketch::Repository.new(directory)
      repository.teach(square, 'triângulo')
      correction = repository.teach(square, 'quadrado')
      assert correction[:corrected]
      assert_equal 1, repository.summary[:count]
      assert_equal 'quadrado', repository.identify(square)[:label]
      repository.teach(square, 'quadrado')
      assert_equal 1, repository.summary[:count]
    end
  end

  def test_closed_outlines_and_filled_figures_have_the_same_silhouette
    processor = Sketch::Preprocessor.new
    assert_equal processor.call(square).mask, processor.call(square(outline: true)).mask
  end

  def test_training_variants_scale_and_move_the_drawing
    named = Sketch::Preprocessor.new.call(square).named_variants
    %w[original maior menor esquerda direita cima baixo].each do |name|
      assert named[name], "missing #{name}"
    end
    assert_operator named['maior'].count('1'), :>, named['menor'].count('1')
    assert_operator centroid_x(named['esquerda']), :<, centroid_x(named['direita'])
    assert_operator centroid_y(named['cima']), :<, centroid_y(named['baixo'])
  end

  def test_small_drawings_still_get_six_modified_presentations_without_rotation
    prepared = Sketch::Preprocessor.new.call(square(left: 3, top: 4, side: 3))
    assert_equal 6, prepared.variants.size
    assert_equal 7, prepared.named_variants.size
    assert_equal prepared.named_variants.values_at('maior', 'menor', 'esquerda', 'direita', 'cima', 'baixo'), prepared.variants
    assert_equal 6, Sketch::Preprocessor.new.variants_from_mask(prepared.mask).size
    # A figura assimétrica conserva a orientação em todas as versões.
    triangle_versions = Sketch::Preprocessor.new.call(triangle).variants
    triangle_versions.each do |mask|
      rows = mask.chars.each_slice(32).map { |row| row.count('1') }.reject(&:zero?)
      assert_operator rows.last, :>, rows.first
    end
  end

  def test_convolution_filters_are_trained_and_persist_after_reload
    model = { 'labels' => [], 'weights' => [], 'bias' => [] }
    mask = Sketch::Preprocessor.new.call(square).mask
    classifier = Sketch::Classifier.new
    classifier.train(model, [['quadrado', mask]])
    kernels = Marshal.load(Marshal.dump(model['conv']['kernels']))
    classifier.train(model, [['quadrado', Sketch::Preprocessor.new.call(triangle).mask]])
    refute_equal kernels, model['conv']['kernels']
    assert model['conv']['kernels'].flatten.all?(&:finite?)
  end

  def test_migration_preserves_examples_and_backs_up_the_old_model
    Dir.mktmpdir do |directory|
      mask = Sketch::Preprocessor.new.call(square).mask
      original = { 'algorithm' => 'softmax_weights', 'labels' => ['quadrado'],
                   'examples' => [{ 'id' => 'a' * 64, 'label' => 'quadrado', 'mask' => mask }] }
      path = File.join(directory, 'model.json')
      File.write(path, JSON.generate(original))
      repository = Sketch::Repository.new(directory)
      assert_equal 'quadrado', repository.identify(square)[:label]
      assert_equal 1, repository.summary[:count]
      assert_equal original, JSON.parse(File.read("#{path}.before-cnn.bak"))
      converted = JSON.parse(File.read(path))
      assert_equal 'cnn_v1', converted['algorithm']
      assert_equal original['examples'], converted['examples']
    end
  end

  def test_input_validation_and_invalid_labels_do_not_write_a_model
    Dir.mktmpdir do |directory|
      repository = Sketch::Repository.new(directory)
      [nil, [], Array.new(4096, 255), Array.new(4096, -1), Array.new(4096, '0')].each do |pixels|
        assert_raises(ArgumentError) { repository.teach(pixels, 'quadrado') }
      end
      ['', '<script>', 'a' * 31].each do |label|
        assert_raises(ArgumentError) { repository.teach(square, label) }
      end
      refute File.exist?(File.join(directory, 'model.json'))
      assert_nil repository.sample_path('../model.json')
    end
  end

  def test_two_concurrent_teachings_are_both_persisted
    Dir.mktmpdir do |directory|
      first = Thread.new { Sketch::Repository.new(directory).teach(square, 'quadrado') }
      second = Thread.new { Sketch::Repository.new(directory).teach(triangle, 'triângulo') }
      [first, second].each(&:value)
      assert_equal 2, Sketch::Repository.new(directory).summary[:count]
    end
  end

  private

  def centroid_x(mask)
    xs = []
    mask.each_char.with_index { |bit, i| xs << (i % 32) if bit == '1' }
    xs.sum / xs.size.to_f
  end

  def centroid_y(mask)
    ys = []
    mask.each_char.with_index { |bit, i| ys << (i / 32) if bit == '1' }
    ys.sum / ys.size.to_f
  end
end
