class Stout::Fog
  def self.fog(path, name = "", &block)
    if name == ""
      name = path
    end

    if File.exists?(path)
      puts "using #{name} in #{path}"
    else
      yield
      puts "#{name} generated in #{path}"
    end
  end
end
