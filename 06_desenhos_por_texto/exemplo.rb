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

# Texto vira numeros, como no 05. Imagens viram numeros, como no 03.
def palavras(texto)
  texto.unicode_normalize(:nfd).gsub(/\p{Mn}/, '').downcase.scan(/[a-z0-9]+/)
end

def vetor(texto, vocabulario)
  presentes = palavras(texto)
  vocabulario.map { |palavra| presentes.include?(palavra) ? 1.0 : 0.0 }
end

def restaurar(dados, tamanho)
  rede = RedeNeural.new(quantidade_entradas: tamanho)
  rede.pesos.merge!(dados.fetch('pesos'))
  rede.vieses.merge!(dados.fetch('vieses'))
  rede
end

def treinar
  imagens = JSON.parse(File.read(File.join(__dir__, 'imagens.json'), encoding: 'utf-8'))
  unless !imagens.empty? && imagens.values.all? { |pixels| pixels.is_a?(Array) && pixels.length == 256 && pixels.all? { |p| p.is_a?(Numeric) && p.finite? && p.between?(0, 1) } }
    raise 'Cada imagem deve ter 256 valores entre 0 e 1.'
  end
  pedidos = []
  File.foreach(File.join(__dir__, 'pedidos.txt'), encoding: 'bom|utf-8').with_index(1) do |linha, numero|
    next if linha.strip.empty? || linha.lstrip.start_with?('#')

    pedido, figura = linha.strip.split(':', 2).map(&:strip)
    unless pedido && !palavras(pedido).empty? && imagens.key?(figura)
      raise "Linha #{numero}: use pedido: figura cadastrada em imagens.json."
    end
    pedidos << [pedido, figura]
  end
  raise 'Adicione pedidos para todas as figuras.' unless pedidos.map(&:last).uniq.sort == imagens.keys.sort
  # Pedidos equivalentes nao podem ensinar figuras diferentes.
  pedidos.group_by { |pedido, _| palavras(pedido).uniq.sort }.each_value do |grupo|
    raise 'Pedidos equivalentes com figuras diferentes.' if grupo.map(&:last).uniq.length > 1
  end
  vocabulario = pedidos.flat_map { |pedido, _| palavras(pedido) }.uniq.sort
  texto = RedeNeural.new(quantidade_entradas: vocabulario.length)
  visao = RedeNeural.new(quantidade_entradas: 256)
  imagens.each_key { |figura| texto.validar_peso(figura); visao.validar_peso(figura) }
  exemplos = pedidos.map { |pedido, figura| [vetor(pedido, vocabulario), figura] }
  ordem = Random.new(42)
  500.times do
    exemplos.shuffle!(random: ordem)
    exemplos.each { |entrada, figura| texto.treinar(entrada, figura, taxa: 0.03) }
  end
  300.times do
    imagens.each { |figura, pixels| visao.treinar(pixels, figura, taxa: 0.001) }
  end
  unless imagens.all? { |figura, pixels| visao.prever(pixels) == figura }
    raise 'A rede de imagens nao reconheceu todos os exemplos. Revise a base.'
  end
  modelo = {
    'vocabulario' => vocabulario,
    'texto' => { 'pesos' => texto.pesos, 'vieses' => texto.vieses },
    'visao' => { 'pesos' => visao.pesos, 'vieses' => visao.vieses },
    'figuras' => imagens
  }
  File.write(File.join(__dir__, 'classificador.json'), JSON.pretty_generate(modelo) + "\n", encoding: 'utf-8')
  acertos = exemplos.count { |entrada, figura| texto.prever(entrada) == figura }
  puts "Treino salvo. Texto: #{acertos}/#{exemplos.length}. Imagens: #{imagens.length}/#{imagens.length}."
  modelo
end

def desenhar(pedido, modelo, texto, visao)
  conhecidas = palavras(pedido) & modelo.fetch('vocabulario')
  # Verbos como desenhar, sem palavras que indiquem uma figura, sao insuficientes.
  comuns = %w[desenhe desenha desenho quero um uma de faca mostre forma a por favor]
  if (conhecidas - comuns).empty?
    puts 'Diga qual figura: quadrado, triângulo ou bola.'
    return
  end
  figura = texto.prever(vetor(pedido, modelo['vocabulario']))
  pixels = modelo.fetch('figuras').fetch(figura)
  reconhecida = visao.prever(pixels)
  raise 'A figura selecionada nao foi confirmada pela rede de imagens.' unless reconhecida == figura

  puts "Desenho: #{figura} (confirmado pela rede de imagens)"
  pixels.each_slice(16) { |linha| puts linha.map { |p| p >= 0.5 ? '##' : '  ' }.join }
  # Desenha os pixels da referencia reconhecida, sem codificar formas geometricas.
  svg = ['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="320" height="320">',
         '<rect width="16" height="16" fill="white"/>']
  pixels.each_with_index do |pixel, i|
    cinza = ((1 - pixel) * 255).round.clamp(0, 255)
    svg << "<rect x=\"#{i % 16}\" y=\"#{i / 16}\" width=\"1\" height=\"1\" fill=\"rgb(#{cinza},#{cinza},#{cinza})\"/>"
  end
  svg << '</svg>'
  pasta = File.join(__dir__, 'desenhos')
  Dir.mkdir(pasta) unless Dir.exist?(pasta)
  caminho = File.join(pasta, "#{figura}.svg")
  File.write(caminho, svg.join("\n"), encoding: 'utf-8')
  puts "Arquivo: #{caminho}"
end

if __FILE__ == $PROGRAM_NAME
  begin
    if ARGV == ['--treinar']
      treinar
      exit
    end
    caminho = File.join(__dir__, 'classificador.json')
    modelo = File.file?(caminho) ? JSON.parse(File.read(caminho, encoding: 'utf-8')) : treinar
    texto = restaurar(modelo.fetch('texto'), modelo.fetch('vocabulario').length)
    visao = restaurar(modelo.fetch('visao'), 256)
    if ARGV.any?
      desenhar(ARGV.join(' '), modelo, texto, visao)
    else
      puts 'Peça um desenho de quadrado, triângulo ou bola. Digite /sair para encerrar.'
      loop do
        print '> '
        pedido = $stdin.gets
        break if pedido.nil? || pedido.strip == '/sair'
        next if pedido.strip.empty?

        desenhar(pedido.strip, modelo, texto, visao)
      end
    end
  rescue StandardError => erro
    abort "Erro: #{erro.message}"
  end
end


