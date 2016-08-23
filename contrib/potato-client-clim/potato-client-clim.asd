(asdf:defsystem #:potato-client-clim
  :description "Potato client in CLIM"
  :license "Apache"
  :serial t
  :depends-on (:mcclim
               :drakma
               :log4cl
               :st-json
               :flexi-streams
               :bordeaux-threads
               :lparallel
               :containers
               :potato-client)
  :components ((:module "src"
                        :serial t
                        :components ((:file "package")
                                     (:file "notifications")
                                     (:file "main")))))
