class SimpleUSAMapIconWdgt extends IconWdgt

  #: printing

  # stated rather than derived: an acronym keeps its capitals
  colloquialName: -> "simple USA map icon"

  #: initialization

  createAppearance: -> new SimpleUSAMapIconAppearance @


