require_relative './config_struct'
require_relative './config_load_error'

class ConfigLoader
  attr_reader :config

  def initialize(path, overrides = [])
    begin
      @config = process_config_file(File.open(path), overrides)
    rescue Errno::ENOENT
      puts "File not found. Check the specified path"
    end
  end

  def process_config_file(file, overrides)
    config = ConfigStruct.new
    target_group = config
    overrides = overrides.map(&:to_s)
    begin
      file.each { |line| target_group = process_line(line, config, target_group, overrides) }
    rescue ConfigLoadError => e
      puts e.message
    end
    config
  end

  def process_line(line, config, target_group, overrides)
    line.gsub!("\n",'')
    if line.gsub(/\s+/, "").length == 0
      # Blank line
    elsif line[0] == ';'
      # Comment line
    elsif line.include?('[') || line.include?(']')
      # Group line
      target_group = process_group_line(line, config)
    elsif line.include?(' = ')
      # Setting line
      process_setting_line(line, target_group, overrides)
    else
      raise ConfigLoadError.new('Bad line syntax')
    end
    target_group
  end

  def process_group_line(line, config)
    validate_group_line(line)
    group_name = line[1..-2]
    config[group_name.to_sym] = ConfigStruct.new
    config[group_name.to_sym]
  end

  def validate_group_line(line)
    raise group_error if line[0] != '[' || line[-1] != ']'
    raise group_error if line.count('[') != 1 || line.count(']') != 1
    raise group_error if line.length < 3
  end

  def group_error
    raise ConfigLoadError.new('Error in group syntax')
  end

  def process_setting_line(line, target_group, overrides)
    left_side, right_side = line.split(' = ')
    field, enabled = process_field(left_side, overrides)
    value = process_value(right_side)
    target_group[field.to_sym] = value if enabled
  end

  def process_field(left_side, overrides)
    if left_side.include?('<') || left_side.include?('>')
      raise override_error if left_side[-1] != '>'
      raise override_error if left_side.count('<') != 1 || left_side.count('>') != 1
      field, override_part = left_side.split('<')
      override_name = override_part.gsub('>','')
      raise override_error if override_name.length < 1
      enabled = overrides.include?(override_name)
      return field, enabled
    else
      return left_side, true
    end
  end

  def process_value(right_side)
    unprocessed_value = right_side.split(';').first
    if unprocessed_value =~ /\d+/
      # Digit
      return unprocessed_value.to_i
    elsif right_side.include?("\"")
      # String
      raise value_error if right_side[0] != "\"" || right_side[-1] != "\""
      raise value_error if right_side.count('\"') != 2
      return right_side[1..-2]
    elsif right_side[0] == '/'
      # Path
      return right_side
    elsif right_side.include?(',')
      return right_side.split(',')
    # TODO Requirements about boolean fields are not clear. I implemented it only for 'yes'/true or 'no'/false.
    # I decided to include yes, no, true, false, because 0 and 1 can be easily processed as digits
    elsif right_side == 'no' || right_side == 'false'
      # No/false
      return false
    elsif right_side == 'yes' || right_side == 'true'
      # Yes/true
      return true
    else
      value_error
    end
  end

  def value_error
    raise ConfigLoadError.new('Error in value syntax')
  end

  def override_error
    raise ConfigLoadError.new('Error in override syntax')
  end
end
