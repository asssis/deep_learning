require 'json'
require 'open3'

class RedeNeural
  attr_reader :pesos, :vieses

  def initialize(quantidade_entradas: 2, seed: 42)
    @quantidade_entradas = quantidade_entradas
    @random = Random.new(seed)
    @pesos = {}
    @vieses = {}
  end

  # Cada resultado tem sua propria lista de pesos.
  def validar_peso(resultado)
    return if @pesos.key?(resultado)

    @pesos[resultado] = Array.new(@quantidade_entradas) do
      @random.rand(-0.5..0.5)
    end
    @vieses[resultado] = 0.0
  end

  def treinar(entrada, resultado, taxa: 0.1)
    validar_peso(resultado)
    erros = {}

    @pesos.each do |classe, pesos|
      soma = calcular_peso(entrada, pesos, @vieses[classe])
      alvo = classe == resultado ? 1 : 0
      erro = calcular_erro_peso(soma, alvo)
      ajustar_pesos(entrada, pesos, erro, taxa)
      ajustar_vies(classe, erro, taxa)
      erros[classe] = erro
    end

    erros
  end

  # Retorna o resultado com a maior soma.
  def prever(entrada)
    @pesos.keys.max_by do |resultado|
      calcular_peso(entrada, @pesos[resultado], @vieses[resultado])
    end
  end

  private

  # Soma cada entrada multiplicada pelo peso correspondente, mais o vies.
  def calcular_peso(entrada, pesos, vies)
    unless entrada.length == pesos.length
      raise ArgumentError, "A entrada deve ter #{pesos.length} valores."
    end

    soma = vies # Soma inicial, mesmo quando todas as entradas sao zero.
    pesos.each_index do |indice|
      soma += entrada[indice] * pesos[indice]
    end
    soma
  end

  # O vies aprende sem multiplicar pela entrada.
  def ajustar_vies(classe, erro, taxa)
    @vieses[classe] -= taxa * erro
  end

  def calcular_erro_peso(soma, alvo)
    soma - alvo
  end

  def calcular_diferenca_peso(entrada, erro, taxa)
    taxa * erro * entrada
  end

  def ajustar_pesos(entrada, pesos, erro, taxa)
    pesos.each_index do |indice|
      ajuste = calcular_diferenca_peso(entrada[indice], erro, taxa)
      pesos[indice] -= ajuste
    end
  end
end

# Como no 03, Python apenas converte o arquivo em uma lista de numeros.
# Treinamento e previsao continuam inteiramente em Ruby.
def carregar_audio(caminho)
  # WSL usa caminhos Linux: nunca selecionar o .exe do ambiente Windows.
  candidatos = if Gem.win_platform?
    [File.join(__dir__, '.venv', 'Scripts', 'python.exe')]
  else
    [File.join(__dir__, '.venv-wsl', 'bin', 'python'),
     File.join(__dir__, '.venv', 'bin', 'python')]
  end
  python = ENV.fetch('PYTHON') do
    candidatos.find { |arquivo| File.file?(arquivo) } ||
      (Gem.win_platform? ? 'python' : 'python3')
  end
  conversor = File.join(__dir__, 'audio.py')
  begin
    saida, erro, status = Open3.capture3(python, conversor, caminho.to_s)
  rescue Errno::ENOENT
    raise "Python nao encontrado: #{python}. Configure PYTHON; veja o README.md."
  end
  raise "Falha ao ler audio #{caminho}: #{erro}" unless status.success?

  JSON.parse(saida)
end

if __FILE__ == $PROGRAM_NAME
  classes = {quadrado: 1, triangulo: 2, bola: 3}
  exemplos = []
  classes.each do |nome, classe|
    pasta = File.join(__dir__, 'sons', nome.to_s)
    arquivos = Dir.glob(File.join(pasta, '*.wav')).sort
    abort "Grave exemplos em #{pasta}. Veja o README.md." if arquivos.empty?

    arquivos.each do |arquivo|
      exemplos << [arquivo, carregar_audio(arquivo), classe]
    end
  end

  rede = RedeNeural.new(quantidade_entradas: 16 * 16)
  classes.each_value { |classe| rede.validar_peso(classe) }
  ordem = Random.new(42)
  500.times do
    exemplos.shuffle!(random: ordem)
    exemplos.each do |_, entrada, classe|
      rede.treinar(entrada, classe, taxa: 0.005)
    end
  end

  puts 'Conferencia com os proprios audios de treinamento:'
  acertos = 0
  exemplos.each do |arquivo, entrada, classe|
    previsto = rede.prever(entrada)
    acertos += 1 if previsto == classe
    puts "#{File.basename(arquivo)} (#{classes.key(classe)}) => #{classes.key(previsto)}"
  end
  puts "Acertos no treino: #{acertos}/#{exemplos.length}"

  if ARGV[0]
    previsto = rede.prever(carregar_audio(ARGV[0]))
    puts "Audio novo: #{ARGV[0]} => #{classes.key(previsto)}"
  end
end
