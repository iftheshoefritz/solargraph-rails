class String
  # Still needed after https://github.com/ruby/gem_rbs_collection/pull/1121:
  # without it String#as_json is not String on Solargraph 0.60.4 and later.
  # @return [String]
  def as_json; end
end
