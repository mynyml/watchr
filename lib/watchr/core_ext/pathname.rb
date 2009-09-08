class Pathname
  def /(path)
    self.join(path).expand_path
  end
end
