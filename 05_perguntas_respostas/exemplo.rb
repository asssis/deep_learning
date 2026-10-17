require 'json'

# Mesmo aprendizado linear: soma, erro e ajuste de pesos e vies.
class RedeNeural
  attr_reader :pesos, :vieses

  def initialize(quantidade_entradas: 2, seed: 42)
    @quantidade_entradas = quantidade_entradas
    @random = Random.new(seed)
    @pesos, @vieses = {}, {}
  end

  def validar_peso(classe)
    return if @pesos.key?(classe)

    @pesos[classe] = Array.new(@quantidade_entradas) { @random.rand(-0.5..0.5) }
    @vieses[classe] = 0.0
  end

  def treinar(entrada, resultado, taxa: 0.1)
    validar_peso(resultado)
    ativos = entrada.each_index.select { |i| entrada[i] != 0 }
    @pesos.each do |classe, pesos|
      soma = @vieses[classe] + ativos.sum { |i| entrada[i] * pesos[i] }
      erro = soma - (classe == resultado ? 1 : 0)
      # Entradas zero nao alteram a soma nem os pesos; podemos pular essas posicoes.
      ativos.each { |i| pesos[i] -= taxa * erro * entrada[i] }
      @vieses[classe] -= taxa * erro
    end
  end

  def prever(entrada)
    ativos = entrada.each_index.select { |i| entrada[i] != 0 }
    @pesos.keys.max_by do |classe|
      @vieses[classe] + ativos.sum { |i| entrada[i] * @pesos[classe][i] }
    end
  end
end

# Preparacao do texto fora da rede; apenas bibliotecas padrao de Ruby.
module Texto
  def self.palavras(texto)
    texto.unicode_normalize(:nfd).gsub(/\p{Mn}/, '').downcase.scan(/[a-z0-9]+/)
  end

  def self.vetor(texto, vocabulario)
    presentes = palavras(texto).uniq
    vocabulario.map { |palavra| presentes.include?(palavra) ? 1.0 : 0.0 }
  end

  def self.carregar(caminho)
    conteudo = File.read(caminho, encoding: 'bom|utf-8')
    itens = []
    entradas = {}
    conteudo.each_line.with_index(1) do |linha, numero|
      next if linha.strip.empty? || linha.lstrip.start_with?('#')

      pergunta, resposta = linha.strip.split(':', 2)
      if pergunta.nil? || pergunta.strip.empty? || resposta.nil? || resposta.strip.empty?
        raise "Linha #{numero}: use pergunta: resposta."
      end
      pergunta, resposta = pergunta.strip, resposta.strip
      # A rede ignora a ordem das palavras: entradas iguais nao podem ter alvos diferentes.
      chave = palavras(pergunta).uniq.sort
      raise "Linha #{numero}: pergunta sem palavras validas." if chave.empty?
      if entradas.key?(chave) && entradas[chave] != resposta
        raise "Linha #{numero}: pergunta equivalente a outra com resposta diferente."
      end
      entradas[chave] = resposta
      item = itens.find { |existente| existente['resposta'] == resposta }
      unless item
        item = { 'classe' => "resposta_#{itens.length + 1}", 'perguntas' => [], 'resposta' => resposta }
        itens << item
      end
      item['perguntas'] << pergunta unless item['perguntas'].include?(pergunta)
    end
    raise 'Adicione pelo menos uma linha pergunta: resposta ao documento.' if itens.empty?

    itens
  end
end

CONFIG = File.join(__dir__, 'classes.json')
DOCUMENTO = File.join(__dir__, 'perguntas_respostas.txt')
MODELO = File.join(__dir__, 'classificador.json')

def treinar
  config = JSON.parse(File.read(CONFIG, encoding: 'bom|utf-8'))
  epocas = config.fetch('epocas')
  taxa = config.fetch('taxa')
  unless epocas.is_a?(Integer) && epocas.positive? && taxa.is_a?(Numeric) && taxa.positive? && taxa.finite?
    raise 'Epocas e taxa devem ser numeros positivos; epocas deve ser inteiro.'
  end
  itens = Texto.carregar(DOCUMENTO)
  classes = itens.map { |item| item['classe'] }

  vocabulario = itens.flat_map { |item| item['perguntas'].flat_map { |p| Texto.palavras(p) } }.uniq.sort
  raise 'Nenhuma palavra encontrada nas perguntas.' if vocabulario.empty?

  exemplos = itens.flat_map do |item|
    item['perguntas'].map { |p| [Texto.vetor(p, vocabulario), item['classe']] }
  end
  rede = RedeNeural.new(quantidade_entradas: vocabulario.length)
  classes.each { |classe| rede.validar_peso(classe) }
  ordem = Random.new(42)
  epocas.times do
    exemplos.shuffle!(random: ordem)
    exemplos.each { |entrada, classe| rede.treinar(entrada, classe, taxa: taxa) }
  end
  raise 'Treinamento divergiu. Reduza a taxa em classes.json.' unless rede.pesos.values.flatten.all?(&:finite?) && rede.vieses.values.all?(&:finite?)

  modelo = {
    'versao' => 2,
    'vocabulario' => vocabulario, 'pesos' => rede.pesos, 'vieses' => rede.vieses,
    'respostas' => itens.to_h { |item| [item['classe'], item['resposta']] },
    'resposta_desconhecida' => config.fetch('resposta_desconhecida')
  }
  File.write(MODELO, JSON.pretty_generate(modelo) + "\n", encoding: 'utf-8')
  acertos = exemplos.count { |entrada, classe| rede.prever(entrada) == classe }
  puts "Classificador salvo em classificador.json. Acertos no treino: #{acertos}/#{exemplos.length}."
  modelo
end

def responder(pergunta, modelo, rede)
  entrada = Texto.vetor(pergunta, modelo.fetch('vocabulario'))
  if entrada.all?(&:zero?)
    puts modelo.fetch('resposta_desconhecida')
    return
  end
  classe = rede.prever(entrada)
  puts "Classe: #{classe}"
  puts "Resposta: #{modelo.fetch('respostas').fetch(classe)}"
end

if __FILE__ == $PROGRAM_NAME
  begin
    if ARGV == ['--treinar']
      treinar
      exit
    end
    modelo = if File.file?(MODELO)
      JSON.parse(File.read(MODELO, encoding: 'utf-8'))
    else
      treinar
    end
    rede = RedeNeural.new(quantidade_entradas: modelo.fetch('vocabulario').length)
    # Recarrega os pesos e vieses do JSON sem alterar o algoritmo da classe.
    rede.pesos.merge!(modelo.fetch('pesos'))
    rede.vieses.merge!(modelo.fetch('vieses'))
    if ARGV.any?
      responder(ARGV.join(' '), modelo, rede)
    else
      puts 'Digite uma pergunta (ou /sair para encerrar).'
      loop do
        print '> '
        linha = $stdin.gets
        break if linha.nil? || linha.strip == '/sair'
        next if linha.strip.empty?

        responder(linha.strip, modelo, rede)
      end
    end
  rescue StandardError => erro
    abort "Erro: #{erro.message}"
  end
end

