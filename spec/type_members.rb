# Solargraph is removing ComplexType's collection API, and #unioned_items
# replaces it. The versions this suite supports span both, so ask which is
# there rather than keying off a version number - #unioned_items has not
# shipped in a release yet.
module TypeMembers
  UNIONED_ITEMS = Solargraph::ComplexType.method_defined?(:unioned_items)

  # @return [Array<String>] one tag per member of a union
  def member_tags(type)
    return type.unioned_items.map(&:tags) if UNIONED_ITEMS

    type.map(&:tag)
  end
end
