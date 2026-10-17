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

# A conversao da imagem fica fora da rede.
# Pillow le PNG/JPG; Ruby recebe apenas uma lista de numeros.
def carregar_imagem(caminho)
  python_local = File.join(__dir__, '.venv', 'bin', 'python')
  python = ENV.fetch('PYTHON') do
    File.exist?(python_local) ? python_local : 'python3'
  end
  conversor = File.join(__dir__, 'imagem.py')
  saida, erro, status = Open3.capture3(python, conversor, caminho)
  raise "Falha ao ler imagem: #{erro}" unless status.success?

  JSON.parse(saida)
end

classe = {quadrado: 1, triangulo: 2, bola: 3}
rede = RedeNeural.new(quantidade_entradas: 16 * 16)
exemplos = {}
classe.each_key do |nome|
  caminho = File.join(__dir__, 'imagens', "#{nome}.png")
  exemplos[nome] = carregar_imagem(caminho)
end

300.times do
  exemplos.each do |nome, entrada|
    rede.treinar(entrada, classe[nome], taxa: 0.001)
  end
end

exemplos.each do |nome, entrada|
  puts "#{nome}.png => #{classe.key(rede.prever(entrada))}"
end

if ARGV[0]
  entrada = carregar_imagem(ARGV[0])
  puts "#{ARGV[0]} => #{classe.key(rede.prever(entrada))}"
end
