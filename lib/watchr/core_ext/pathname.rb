class Pathname #:nodoc:
  def /(path)
    self.join(path).expand_path
  end
end
