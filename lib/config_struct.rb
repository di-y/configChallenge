class ConfigStruct < Hash
  def method_missing(method, *args)
    if method[-1] == '='
      self[method[0..-2]] = args.first
    else
      self[method]
    end
  end
end
