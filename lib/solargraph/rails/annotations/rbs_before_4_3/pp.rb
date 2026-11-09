# https://github.com/ruby/rbs/pull/3234
module PP::ObjectMixin
  # @param q [PP]
  # @return [void]
  def pretty_print(q); end
end
