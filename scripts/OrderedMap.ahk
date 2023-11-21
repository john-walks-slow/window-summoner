getOrderedKeys(args*) {
  keys := []
  isKey := true
  for k in args {
    if (isKey) {
      keys.Push(k)
      isKey := false
    } else {
      isKey := true
    }
  }
  return keys
}

class OrderedMap extends Map {
  __New(args*) {
    this.Keys(getOrderedKeys(args*))
    return super.__New(args*)
  }
  Keys(newValue := unset) {
    static keys := []
    if IsSet(newValue) {
      keys := newValue
    }
    return keys
  }
}