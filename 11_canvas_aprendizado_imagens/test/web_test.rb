ENV['RAILS_ENV'] = 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'tmpdir'
require_relative 'raster_fixtures'

class CanvasWebTest < ActionDispatch::IntegrationTest
  include RasterFixtures

  setup do
    @directory = Dir.mktmpdir
    @previous_storage = Rails.configuration.x.sketch_storage
    Rails.configuration.x.sketch_storage = @directory
    get '/'
    @csrf = Nokogiri::HTML(response.body).at_css('meta[name="csrf-token"]')['content']
  end

  teardown do
    Rails.configuration.x.sketch_storage = @previous_storage
    FileUtils.remove_entry(@directory)
  end

  def send_json(path, payload)
    post path, params: payload, as: :json, headers: { 'X-CSRF-Token' => @csrf }
    JSON.parse(response.body)
  end

  test 'canvas page and static assets' do
    assert_response :success
    assert_select 'canvas#sketch[width="512"]'
    assert_select '#teach-form input[name=label]'
    assert_select '#teach', text: /Treinar com este desenho/
    assert_select '#image-file[accept*=".svg"]'
    assert_select '#clear', text: 'Limpar quadro'
    assert_select '#download-png'
    assert_select '#download-svg'
    assert_select 'script[src="/image_io.js"]'
    assert_select '#sample-count', text: '0'
    assert_select '#pretrain', text: 'Treinar com exemplos de teste'
    assert_select '#reset-training', text: 'Limpar modelo'
    assert_select '.training-actions button', count: 2
    assert_select '#restore-training', count: 0
    assert_select '.starter-gallery', count: 0
    assert_select '[role=tablist] [role=tab]', count: 2
    assert_select '#learning-tab[aria-selected=true]'
    assert_select '#learning-panel:not([hidden]) canvas#sketch'
    assert_select '#examples-panel[hidden] #examples'
    assert_select '#examples-panel #pretrain'
    assert_select '#examples-panel #reset-training'
    assert_select '#learning-panel .training-actions', count: 0
    get '/canvas.js'
    assert_response :success
    get '/canvas.css'
    assert_response :success
    get '/image_io.js'
    assert_response :success
  end

  test 'draw identify teach identify and reload persisted images' do
    first = send_json('/identificar', pixels: square)
    assert_response :success
    assert_equal 'unknown', first['status']
    trained = send_json('/ensinar', pixels: square, label: 'Isso é um trinagulo')
    assert_equal 'learned', trained['status']
    assert_equal 'triângulo', trained['label']
    found = send_json('/identificar', pixels: square(left: 8, top: 5, side: 30))
    assert_equal 'recognized', found['status']
    assert_equal 'triângulo', found['label']
    get '/'
    assert_select '#sample-count', text: '1'
    assert_select '#examples img', count: 1
    assert_select '#examples figcaption', text: 'triângulo'
    assert_select '#examples a[download="triângulo.png"]'
    get trained['summary']['examples'].first['url']
    assert_response :success
    assert_equal 'image/png', response.media_type
    assert_equal [64, 64], [ChunkyPNG::Image.from_blob(response.body).width, ChunkyPNG::Image.from_blob(response.body).height]
  end

  test 'invalid input and missing samples' do
    data = send_json('/identificar', pixels: Array.new(4096, 255))
    assert_response :unprocessable_entity
    assert_match /Desenhe/, data['error']
    send_json('/ensinar', pixels: square, label: '<script>')
    assert_response :unprocessable_entity
    get "/exemplos/#{'a' * 64}"
    assert_response :not_found
  end

  test 'csrf is required for learning' do
    post '/ensinar', params: { pixels: square, label: 'quadrado' }, as: :json
    assert_response :unprocessable_entity
    refute File.exist?(File.join(@directory, 'model.json'))
    %w[inicial zerar restaurar].each do |action|
      post "/treinamento/#{action}", params: {}, as: :json
      assert_response :unprocessable_entity
    end
  end

  test 'starter image previews do not train the model' do
    %w[estrela quadrado bola triangulo retangulo].each do |key|
      get "/base-imagens/#{key}.png"
      assert_response :success
      assert_equal 'image/png', response.media_type
      image = ChunkyPNG::Image.from_blob(response.body)
      assert_equal [64, 64], [image.width, image.height]
    end
    get '/base-imagens/inexistente.png'
    assert_response :not_found
    assert_equal 0, Sketch::Repository.new(@directory).summary[:count]
  end

  test 'pretrain reset and restore preserve the saved model and PNGs' do
    assert_equal 'unknown', send_json('/identificar', pixels: square)['status']
    trained = send_json('/treinamento/inicial', {})
    assert_response :success
    assert_equal 'pretrained', trained['status']
    assert_equal 25, trained['added']
    assert_equal 25, trained['summary']['count']
    assert_equal 25, trained['summary']['examples'].size
    assert_equal 5, trained['summary']['examples'].count { |sample| sample['label'] == 'estrela' }
    assert_equal 5, trained['summary']['classes'].size
    assert_equal 6, trained['variants']
    assert_equal 35, trained['epochs']
    Sketch::StarterImages.new.samples.each do |sample|
      found = send_json('/identificar', pixels: sample[:pixels])
      assert_equal sample[:label], found['label'], "Expected #{sample[:label]}, got #{found.inspect}"
    end
    path = File.join(@directory, 'model.json')
    saved = JSON.parse(File.read(path))
    example_url = trained['summary']['examples'].first['url']
    reset = send_json('/treinamento/zerar', {})
    assert_equal 0, reset['summary']['count']
    assert reset['summary']['can_restore']
    assert_equal 'unknown', send_json('/identificar', pixels: square)['status']
    get example_url
    assert_response :not_found
    # Repetir um reset vazio não destrói o backup.
    send_json('/treinamento/zerar', {})
    restored = send_json('/treinamento/restaurar', {})
    assert_equal 25, restored['summary']['count']
    assert_equal saved, JSON.parse(File.read(path))
    get example_url
    assert_response :success
    get '/'
    assert_select '#training-state', text: 'Treinamento salvo em uso'
    assert_select '#restore-training', count: 0
    # A base pode ser solicitada novamente sem duplicar exemplos.
    repeated = send_json('/treinamento/inicial', {})
    assert_equal 0, repeated['added']
    assert_equal 25, repeated['summary']['count']
    assert_equal saved['examples'], JSON.parse(File.read(path))['examples']
  end

  test 'restore without a checkpoint explains the missing saved training' do
    result = send_json('/treinamento/restaurar', {})
    assert_response :unprocessable_entity
    assert_match /não existe/, result['error']
    assert_equal 0, Sketch::Repository.new(@directory).summary[:count]
  end
end
