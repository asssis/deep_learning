# Aprendizado linear didatico em Ruby puro.
# Execute: ruby exemplo.rb

class RedeNeural
  attr_reader :pesos

  def initialize(quantidade_entradas: 2, seed: 42)
    @quantidade_entradas = quantidade_entradas
    @random = Random.new(seed)
    @pesos = {}
  end

  # Cada resultado tem sua propria lista de pesos.
  def validar_peso(resultado)
    return if @pesos.key?(resultado)

    @pesos[resultado] = Array.new(@quantidade_entradas) do
      @random.rand(-0.5..0.5)
    end
  end

  def treinar(entrada, resultado, taxa: 0.1)
    validar_peso(resultado)
    erros = {}

    @pesos.each do |classe, pesos|
      soma = calcular_peso(entrada, pesos)
      alvo = classe == resultado ? 1 : 0
      erro = calcular_erro_peso(soma, alvo)
      ajustar_pesos(entrada, pesos, erro, taxa)
      erros[classe] = erro
    end

    erros
  end

  # Retorna o resultado com a maior soma.
  def prever(entrada)
    @pesos.keys.max_by do |resultado|
      calcular_peso(entrada, @pesos[resultado])
    end
  end

  private

  # Soma: entrada[0] * peso[0] + entrada[1] * peso[1].
  def calcular_peso(entrada, pesos)
    unless entrada.length == pesos.length
      raise ArgumentError, "A entrada deve ter #{pesos.length} valores."
    end

    soma = 0.0
    pesos.each_index do |indice|
      soma += entrada[indice] * pesos[indice]
    end
    soma
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

rede = RedeNeural.new
classe = {gato: 1, cachorro: 2}


# Taxa 1 funciona neste exemplo simples com entradas 0 e 1.
# Para outros dados, pode ser necessário usar uma taxa menor e repetir o treino.
rede.treinar([1, 0], classe[:gato], taxa: 1.0)
rede.treinar([0, 1], classe[:cachorro], taxa: 1.0)

puts "[1, 0] => #{classe.key(rede.prever([1, 0]))}"
puts "[0, 1] => #{classe.key(rede.prever([0, 1]))}"

puts "\nPesos depois do treinamento:"
rede.pesos.each do |resultado, pesos|
  puts "#{classe.key(resultado)}: #{pesos.inspect}"
end
