require 'chunky_png'

module Sketch
  # Estas geometrias só geram dados rotulados de treino, nunca classificam.
  class StarterImages
    SHAPES = { 'estrela' => 'estrela', 'quadrado' => 'quadrado', 'bola' => 'bola',
               'triangulo' => 'triângulo', 'retangulo' => 'retângulo' }.freeze

    def catalog
      SHAPES.map { |key, label| { key: key, label: label, url: "/base-imagens/#{key}.png" } }
    end

    def samples
      SHAPES.flat_map do |key, label|
        (0...5).map { |version| { label: label, pixels: pixels(key, version) } }
      end
    end

    def png(key)
      image = ChunkyPNG::Image.new(64, 64)
      pixels(key).each_with_index { |value, i| image[i % 64, i / 64] = ChunkyPNG::Color.rgb(value, value, value) }
      image.to_blob
    end

    private

    def pixels(key, version = 0)
      raise ArgumentError, 'Imagem de exemplo não encontrada.' unless SHAPES.key?(key)
      cx, cy, radius = [[31.5, 31.5, 23.0], [29.5, 33.5, 19.0], [32.5, 29.5, 21.0], [28.5, 31.5, 18.0], [33.5, 32.5, 22.0]].fetch(version)
      vertices = case key
                 when 'quadrado' then [[-1, -1], [1, -1], [1, 1], [-1, 1]]
                 when 'retangulo' then [[-1, -0.5], [1, -0.5], [1, 0.5], [-1, 0.5]]
                 when 'triangulo' then [[0, -1], [1, 1], [-1, 1]]
                 when 'estrela'
                   10.times.map do |i|
                     angle = -Math::PI / 2 + i * Math::PI / 5
                     r = i.even? ? 1.0 : (version.zero? ? 0.45 : 0.52)
                     [Math.cos(angle) * r, Math.sin(angle) * r]
                   end
                 end
      # Contornos levemente irregulares lembram o traço do canvas.
      # Mantém a orientação: não aplica rotação ou espelhamento.
      if version >= 2 && vertices
        vertices = vertices.each_with_index.map do |(x, y), i|
          offset = (version - 2) * 0.7
          [x + Math.sin(i * 2.3 + 0.6 + offset) * 0.055, y + Math.cos(i * 1.7 + 0.3 + offset) * 0.055]
        end
      end
      filled = Array.new(4096) do |i|
        x, y = (i % 64 - cx) / radius, (i / 64 - cy) / radius
        boundary = version >= 2 ? 1.0 + 0.035 * Math.sin(Math.atan2(y, x) * 3 + 0.4 + (version - 2) * 0.7) : 1.0
        key == 'bola' ? x * x + y * y <= boundary * boundary : inside_polygon?(x, y, vertices)
      end
      return filled.map { |ink| ink ? 30 : 255 } unless version >= 2
      # Uma borda de dois pixels conserva o contorno fechado para o preenchimento.
      Array.new(4096) do |i|
        x, y = i % 64, i / 64
        edge = filled[i] && (-2..2).any? do |dy|
          (-2..2).any? do |dx|
            nx, ny = x + dx, y + dy
            !nx.between?(0, 63) || !ny.between?(0, 63) || !filled[ny * 64 + nx]
          end
        end
        edge ? 30 : 255
      end
    end

    def inside_polygon?(x, y, vertices)
      inside = false
      previous = vertices.last
      vertices.each do |current|
        ax, ay = previous
        bx, by = current
        if (ay > y) != (by > y) && x < (bx - ax) * (y - ay) / (by - ay) + ax
          inside = !inside
        end
        previous = current
      end
      inside
    end
  end
end
