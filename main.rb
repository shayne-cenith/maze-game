require 'set'

STARTING_HEALTH = 200
MAX_MOVES = 450

class GridWorld
	attr_reader :grid, :frontier

	def initialize(grid)
		@grid = grid
		@frontier = Set.new([find_start()])
	end

	def solve
    until @frontier.empty?
      current = @frontier.first
			puts "Current: #{current}"
      @frontier.delete(current)

      neighbors = find_neighbors(current)
      neighbors.each do |neighbor|
        if GridPath.should_move(current, neighbor)
          GridPath.move(current, neighbor)
          @frontier.add(neighbor)
        end
      end
    end
  end

	private

	def find_start()
		@grid.each_with_index do |row, y|
			if row[0].type == 'Start'
				return @grid[y][0]
			end
		end
		raise 'Start not found'
	end

	def find_neighbors(current)
		@neighbor_cache ||= {}
		return @neighbor_cache[current] if @neighbor_cache[current]
	
		neighbors = []
		left = @grid.dig(current.x - 1, current.y)
		neighbors.concat([left]) if left
		right = @grid.dig(current.x + 1, current.y)
		neighbors.concat([right]) if right
		up = @grid.dig(current.x, current.y - 1) 
		neighbors.concat([up]) if up
		down = @grid.dig(current.x, current.y + 1)
		neighbors.concat([down]) if down
	
		@neighbor_cache[current] = neighbors
		neighbors
	end
end


class GridPath
	attr_reader :health, :moves, :history

	def initialize(health = 0, moves = 0, history = [])
		@health = health
		@moves = moves
		@history = history
	end

	def is_strictly_better(other)
    @health >= other.health && @moves >= other.moves &&
			(@health > other.health || @moves > other.moves)
  end

	def valid?
		@health > 0 && @moves > 0
	end

	def navigate(neighbor)
    new_health = @health + neighbor.health_effect
    new_moves = @moves + neighbor.moves_effect
    GridPath.new(new_health, new_moves, @history + [neighbor])
  end

	def to_s
		"Path: Health=#{@health}, Moves=#{@moves}, History=[#{@history.join(' -> ')}]"
	end

	def self.should_move(from, to)
		from.paths.any? do |path|
			new_path = path.dup.navigate(to)
			next false unless new_path.valid?
			to.paths.empty? || !to.paths.any? { |old_path| old_path.is_strictly_better(new_path) }
		end
	end

	def self.move(from, to)
		new_paths = from.paths.map { |path| path.navigate(to) }.select(&:valid?)
		existing_paths = to.paths.reject { |old_path| new_paths.any? { |new_path| new_path.is_strictly_better(old_path) } }
		new_paths_to_add = new_paths.reject { |new_path| existing_paths.any? { |existing| existing.is_strictly_better(new_path) } }
		
		all_paths = (existing_paths + new_paths_to_add).uniq { |path| path.history.map(&:to_s) }
		to.paths = all_paths
	end
end


class GridSpace
  EFFECTS = {
    'A' => { type: 'Start', health: 0, moves: 0 },
    'B' => { type: 'End', health: 0, moves: 0 },

    'E' => { type: 'Blank', health: 0, moves: -1 },
    'S' => { type: 'Speeder', health: -5, moves: 0 },
    'L' => { type: 'Lava', health: -50, moves: -10 },
    'M' => { type: 'Mud', health: -10, moves: -5 }
  }

  attr_reader :type, :display, :health_effect, :moves_effect, :x, :y
	attr_accessor :paths

  def initialize(char, x, y)
    effect = EFFECTS[char]
    @type = effect[:type]
		@display = char
    @health_effect = effect[:health]
    @moves_effect = effect[:moves]
		@x = x
		@y = y

		if @type == 'Start'
			@paths = [GridPath.new(STARTING_HEALTH, MAX_MOVES, [self])]
		else
			@paths = [GridPath.new]
		end
  end

  def to_s
    "#{@display} (#{@x}, #{@y})"
  end
end


def read_char_grid(filename)
	char_grid = []
		File.readlines(filename).each do |line|
			next if line.strip.empty?
			char_grid << line.strip.chars
		end
		char_grid
end

def convert_to_grid_spaces(char_grid)
  char_grid.map.with_index do |row, x|
    row.map.with_index { |char, y| GridSpace.new(char, x, y) }
  end
end

def convert_to_grid_world(char_grid)
	GridWorld.new(convert_to_grid_spaces(char_grid))
end


filename = ARGV[0]
char_grid = read_char_grid(filename)
grid_world = convert_to_grid_world(char_grid)

puts "Grid contents:"
grid_world.grid.each { |row| puts row.join(' ') }
puts "Solving..."
grid_world.solve
puts "Done!"

grid_world.grid.filter { |row| row.any? { |space| space.type == 'End' } }.each do |row|
	row.each do |space|
		if space.type == 'End'
			puts "All paths to End:"
			space.paths.each_with_index do |path, i|
				puts "Path #{i + 1}: Health=#{path.health}, Moves=#{path.moves}, History=[#{path.history.join(' -> ')}]"
			end
		end
	end
end
