require 'set'
require 'sinatra'
require 'json'

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
			current.visits += 1
			puts "Current: #{current}"
			@frontier.delete(current)
			puts "Frontier: #{@frontier.count}"

			neighbors = find_neighbors(current)
			neighbors.each do |neighbor|
				if GridPath.should_move(current, neighbor)
					old_paths = neighbor.paths
					GridPath.move(current, neighbor)
					@frontier.add(neighbor) if neighbor.paths != old_paths
				end
			end
		end
	end

	private

	def find_start()
		@grid.each_with_index do |row, r|
			return row[0] if row[0].type == 'Start'
		end
		raise 'Start not found'
	end

	def find_neighbors(current)
		@neighbor_cache ||= {}
		return @neighbor_cache[current] if @neighbor_cache[current]
		
		neighbors = []

		if current.c > 0
			left = @grid[current.r][current.c - 1]
			neighbors.concat([left])
		end
		if current.c < @grid[0].length - 1
			right = @grid[current.r][current.c + 1]
			neighbors.concat([right])
		end
		if current.r > 0
			up = @grid[current.r - 1][current.c]
			neighbors.concat([up])
		end
		if current.r < @grid.length - 1
			down = @grid[current.r + 1][current.c]
			neighbors.concat([down])
		end
		
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
		@health >= other.health && @moves >= other.moves && (@health > other.health || @moves > other.moves)
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
			to.paths.empty? || !to.paths.any? { |existing_path| existing_path.is_strictly_better(new_path) }
		end
	end

	def self.move(from, to)
		new_paths = from.paths.map { |path| path.navigate(to) }.select(&:valid?)
		existing_paths = to.paths.reject { |old_path| new_paths.any? { |new_path| new_path.is_strictly_better(old_path) } }
		new_paths_to_add = new_paths.reject { |new_path| existing_paths.any? { |existing| existing.is_strictly_better(new_path) } }
		
		all_paths = (existing_paths + new_paths_to_add).uniq { |path| path.history.map(&:to_s) }
		grouped_paths = all_paths.group_by { |path| [path.health, path.moves] }
		optimized_paths = grouped_paths.values.map { |paths| paths.min_by { |path| path.history.length } }
		
		to.paths = optimized_paths
	end
end


EFFECTS = {
	'A' => { type: 'Start', health: 0, moves: 0 },
	'B' => { type: 'End', health: 0, moves: 0 },

	'E' => { type: 'Blank', health: 0, moves: -1 },
	'S' => { type: 'Speeder', health: -5, moves: 0 },
	'L' => { type: 'Lava', health: -50, moves: -10 },
	'M' => { type: 'Mud', health: -10, moves: -5 }
}


class GridSpace
	attr_reader :type, :display, :health_effect, :moves_effect, :r, :c
	attr_accessor :paths, :visits

	def initialize(char, r, c)
		effect = EFFECTS[char]
		@type = effect[:type]
		@display = char
		@health_effect = effect[:health]
		@moves_effect = effect[:moves]
		@r = r
		@c = c
		@visits = 0

		if @type == 'Start'
			@paths = [GridPath.new(STARTING_HEALTH, MAX_MOVES, [self])]
		else
			@paths = [GridPath.new]
		end
	end

	def to_s
		"#{@display} (#{@r}, #{@c}) [#{@visits}v, #{@paths.count}p]"
	end
end


# Returns an array of arrays, where each inner array represents a row of the grid.
def read_char_grid(filename)
	File.readlines(filename)
		.map(&:strip)
		.reject(&:empty?)
		.map { |line| line.split('').select { |c| EFFECTS.key?(c) } }
end

def convert_to_grid_spaces(char_grid)
	grid = char_grid.map.with_index do |row, r|
		row.map.with_index { |char, c| GridSpace.new(char, r, c) }
	end
	grid
end

def convert_to_grid_world(char_grid)
	GridWorld.new(convert_to_grid_spaces(char_grid))
end

def generate_visualization(grid, path)
	visualization = grid.map do |row|
		row.map { |space| space.display }
	end
	
	path.history.each do |space|
		if space.display != 'A' && space.display != 'B'
		visualization[space.r][space.c] = '*'
		end
	end
	
	visualization.map { |row| row.join('') }
end


get '/' do
	content_type :text
	<<~EXAMPLE
	  Example POST request:
	  
	  curl -X POST \\
		-H "Content-Type: application/json" \\
		-d '{"grid":"ASS\\nELB\\nEEE"}' \\
		http://localhost:3000/solve
	EXAMPLE
end

post '/solve' do
	content_type :json
	
	begin
		# Parse the grid from request body
		request_payload = JSON.parse(request.body.read)
		grid_string = request_payload['grid']
		
		# Convert input string to char grid
		char_grid = grid_string.split("\n")
		.map(&:strip)
		.reject(&:empty?)
		.map { |line| line.split('').select { |c| EFFECTS.key?(c) } }
		
		# Create and solve grid world
		grid_world = convert_to_grid_world(char_grid)
		grid_world.solve
		
		# Collect results
		results = []
		grid_world.grid.each do |row|
		row.each do |space|
			if space.type == 'End'
			space.paths.each do |path|
				results << {
				health: path.health,
				moves: path.moves,
				path: path.history.map { |s| { r: s.r, c: s.c, type: s.type } },
				visualization: generate_visualization(grid_world.grid, path)
				}
			end
			end
		end
		end
		
		results.to_json
	rescue => e
		status 400
		{ error: e.message }.to_json
	end
end


if __FILE__ == $0
	set :port, ENV['PORT'] || 3000
	set :bind, '0.0.0.0'
end
