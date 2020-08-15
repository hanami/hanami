Hanami.application.register_bootable :inflector do
  start do
    register :inflector, Hanami.application.inflector
  end
end
