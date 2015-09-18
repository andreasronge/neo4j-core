require 'ext/kernel'

require 'ostruct'
require 'forwardable'
require 'fileutils'

require 'neo4j-core/version'
require 'neo4j/property_validator'
require 'neo4j/property_container'
require 'neo4j-core/active_entity'
require 'neo4j-core/helpers'
require 'neo4j/core/query'

require 'neo4j/entity_equality'
require 'neo4j/node'
require 'neo4j/label'
require 'neo4j/session'
require 'neo4j/ansi'

require 'neo4j/relationship'
require 'neo4j/transaction'

require 'neo4j-server'

require 'rake'
require 'neo4j/rake_tasks'

if RUBY_PLATFORM == 'java' && !ENV['WITHOUT_NEO4J_EMBEDDED']
  require 'neo4j-embedded'
else
  # just for the tests
  module Neo4j
    module Embedded
    end
  end
end
