# https://github.com/ruby/rbs/pull/3234
class Object
  # @param pp [PP]
  # @return [void]
  def pretty_print(pp); end
end
