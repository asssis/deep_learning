# Aprendizado linear didatico em Ruby puro.
# Execute: ruby exemplo.rb

# 1 desenha a forma; 0 representa o fundo.
quadrado = [
  [1, 1, 1, 1, 1],
  [1, 0, 0, 0, 1],
  [1, 0, 0, 0, 1],
  [1, 0, 0, 0, 1],
  [1, 1, 1, 1, 1],
]

triangulo = [
  [0, 0, 1, 0, 0],
  [0, 1, 0, 1, 0],
  [0, 1, 0, 1, 0],
  [1, 0, 0, 0, 1],
  [1, 1, 1, 1, 1],
]

bola = [
  [0, 1, 1, 1, 0],
  [1, 0, 0, 0, 1],
  [1, 0, 0, 0, 1],
  [1, 0, 0, 0, 1],
  [0, 1, 1, 1, 0],
]

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

rede = RedeNeural.new(quantidade_entradas: 25)
classe = {quadrado: 1, triangulo: 2, bola: 3}

# Transformamos cada matriz em uma lista, linha por linha.
quadrado_linear = quadrado.flatten
triangulo_linear = triangulo.flatten
bola_linear = bola.flatten

# Mais entradas pedem uma taxa menor. A repeticao fica fora de treinar.
100.times do
  rede.treinar(quadrado_linear, classe[:quadrado], taxa: 0.01)
  rede.treinar(triangulo_linear, classe[:triangulo], taxa: 0.01)
  rede.treinar(bola_linear, classe[:bola], taxa: 0.01)
end

puts "Quadrado => #{classe.key(rede.prever(quadrado_linear))}"
quadrado.each { |linha| puts linha.map { |valor| valor == 1 ? '██' : '  ' }.join }
puts
puts "Triangulo => #{classe.key(rede.prever(triangulo_linear))}"
triangulo.each { |linha| puts linha.map { |valor| valor == 1 ? '██' : '  ' }.join }
puts
puts "Bola => #{classe.key(rede.prever(bola_linear))}"
bola.each { |linha| puts linha.map { |valor| valor == 1 ? '██' : '  ' }.join }

puts "\nPesos depois do treinamento:"
rede.pesos.each do |resultado, pesos|
  puts "\n#{classe.key(resultado).to_s.upcase}"
  puts "Pesos (mesmas posicoes da matriz):"
  pesos.each_slice(5) do |linha|
    puts linha.map { |peso| format('%8.4f', peso) }.join(' ')
  end
  puts format('Vies: %.4f', rede.vieses[resultado])
end
