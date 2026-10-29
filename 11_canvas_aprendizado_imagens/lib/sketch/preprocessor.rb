module Sketch
  class Preprocessor
    INPUT = 64
    SIDE = 32
    TRAINING_VARIANTS = %w[maior menor esquerda direita cima baixo].freeze
    Result = Struct.new(:mask, :pixels, :ink_count, :variants, :named_variants, keyword_init: true)

    def call(pixels)
      silhouette, bounds, ink_count = silhouette_from(pixels)
      named = augment(silhouette, bounds)
      Result.new(mask: named.fetch('original'), pixels: pixels, ink_count: ink_count, variants: named.values_at(*TRAINING_VARIANTS), named_variants: named)
    end

    # Recupera as seis versões modificadas dos exemplos antigos, sem o PNG.
    def variants_from_mask(mask)
      unless mask.is_a?(String) && mask.match?(/\A[01]{1024}\z/)
        raise ArgumentError, 'A silhueta salva é inválida.'
      end
      pixels = Array.new(INPUT * INPUT) { |i| mask.getbyte((i / INPUT / 2) * SIDE + i % INPUT / 2) == 49 ? 0 : 255 }
      call(pixels).variants
    end

    private

    def silhouette_from(pixels)
      unless pixels.is_a?(Array) && pixels.size == INPUT * INPUT && pixels.all? { |v| v.is_a?(Integer) && v.between?(0, 255) }
        raise ArgumentError, 'A imagem precisa conter 64 × 64 pixels em tons de cinza.'
      end
      ink = pixels.map { |v| v < 200 }
      positions = ink.each_index.select { |i| ink[i] }
      raise ArgumentError, 'Desenhe uma figura no quadro antes de continuar.' if positions.size < 6
      xs, ys = positions.map { |i| i % INPUT }, positions.map { |i| i / INPUT }
      left, right, top, bottom = xs.min, xs.max, ys.min, ys.max
      width, height = right - left + 1, bottom - top + 1
      raise ArgumentError, 'Desenhe uma figura maior, com largura e altura.' if [width, height].min < 3
      [fill_closed_regions(ink), { left: left, top: top, width: width, height: height }, positions.size]
    end

    def augment(silhouette, bounds)
      placements = {
        'original' => :as_drawn,
        'maior' => [:center, 1.45],
        'menor' => [:center, 0.5],
        'esquerda' => [:left, 0.7],
        'direita' => [:right, 0.7],
        'cima' => [:top, 0.7],
        'baixo' => [:bottom, 0.7]
      }
      placements.transform_values do |placement|
        encode(downsample(placement == :as_drawn ? silhouette : stamp(silhouette, bounds, *placement)))
      end
    end

    def stamp(silhouette, bounds, anchor, scale)
      out_width = [(bounds[:width] * scale).round, 1].max.clamp(1, INPUT)
      out_height = [(bounds[:height] * scale).round, 1].max.clamp(1, INPUT)
      dest_left, dest_top = destination(anchor, out_width, out_height)
      canvas = Array.new(INPUT * INPUT, false)
      out_height.times do |y|
        dy = dest_top + y
        next unless dy.between?(0, INPUT - 1)
        source_y = bounds[:top] + ((y + 0.5) * bounds[:height] / out_height).floor.clamp(0, bounds[:height] - 1)
        out_width.times do |x|
          dx = dest_left + x
          next unless dx.between?(0, INPUT - 1)
          source_x = bounds[:left] + ((x + 0.5) * bounds[:width] / out_width).floor.clamp(0, bounds[:width] - 1)
          canvas[dy * INPUT + dx] = silhouette[source_y * INPUT + source_x]
        end
      end
      canvas
    end

    def destination(anchor, width, height)
      margin = 2
      center_x = ((INPUT - width) / 2).clamp(0, INPUT - width)
      center_y = ((INPUT - height) / 2).clamp(0, INPUT - height)
      right = (INPUT - width - margin).clamp(0, INPUT - width)
      bottom = (INPUT - height - margin).clamp(0, INPUT - height)
      left = margin.clamp(0, INPUT - width)
      top = margin.clamp(0, INPUT - height)
      {
        center: [center_x, center_y],
        left: [left, center_y],
        right: [right, center_y],
        top: [center_x, top],
        bottom: [center_x, bottom],
        top_left: [left, top],
        top_right: [right, top],
        bottom_left: [left, bottom],
        bottom_right: [right, bottom]
      }.fetch(anchor)
    end

    def downsample(silhouette)
      Array.new(SIDE * SIDE, false).tap do |out|
        SIDE.times do |y|
          SIDE.times do |x|
            base = (y * 2) * INPUT + (x * 2)
            out[y * SIDE + x] = silhouette[base] || silhouette[base + 1] || silhouette[base + INPUT] || silhouette[base + INPUT + 1]
          end
        end
      end
    end

    def encode(bits) = bits.map { |bit| bit ? '1' : '0' }.join

    def fill_closed_regions(ink)
      exterior, queue = Array.new(ink.size, false), []
      ink.each_index do |i|
        x, y = i % INPUT, i / INPUT
        next unless (x == 0 || y == 0 || x == INPUT - 1 || y == INPUT - 1) && !ink[i]
        exterior[i] = true
        queue << i
      end
      index = 0
      while index < queue.size
        i = queue[index]
        x, y = i % INPUT, i / INPUT
        [[x - 1, y], [x + 1, y], [x, y - 1], [x, y + 1]].each do |nx, ny|
          next unless nx.between?(0, INPUT - 1) && ny.between?(0, INPUT - 1)
          neighbor = ny * INPUT + nx
          next if exterior[neighbor] || ink[neighbor]
          exterior[neighbor] = true
          queue << neighbor
        end
        index += 1
      end
      exterior.map { |outside| !outside }
    end
  end
end
