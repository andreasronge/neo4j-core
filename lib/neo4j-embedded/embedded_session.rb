# Plugin

Neo4j::Session.register_db(:embedded_db) do |*args|
  Neo4j::Embedded::EmbeddedSession.new(*args)
end


module Neo4j::Embedded
  class EmbeddedSession < Neo4j::Session

    class Error < StandardError
    end

    attr_reader :graph_db, :db_location
    extend Forwardable
    extend Neo4j::Core::TxMethods
    def_delegator :@graph_db, :begin_tx


    def initialize(db_location, config={})
      @db_location = db_location
      @auto_commit = !!config[:auto_commit]
      Neo4j::Session.register(self)
      @query_builder = Neo4j::Core::QueryBuilder.new
    end

    def inspect
      "#{self.class} db_location: '#{@db_location}', running: #{running?}"
    end

    def start
      raise Error.new("Embedded Neo4j db is already running") if running?
      puts "Start embedded Neo4j db at #{db_location}"
      factory = Java::OrgNeo4jGraphdbFactory::GraphDatabaseFactory.new
      @graph_db = factory.newEmbeddedDatabase(db_location)
      Neo4j::Session._notify_listeners(:session_available, self)
      @engine = Java::OrgNeo4jCypherJavacompat::ExecutionEngine.new(@graph_db)
    end

    def factory_class
      Java::OrgNeo4jGraphdbFactory::GraphDatabaseFactory
      Java::OrgNeo4jTest::ImpermanentGraphDatabase
    end

    def close
      super
      shutdown
    end

    def shutdown
      graph_db && graph_db.shutdown
      @graph_db = nil
    end

    def running?
      !!graph_db
    end

    def create_label(name)
      EmbeddedLabel.new(self, name)
    end

    def load_node(neo_id)
      _load_node(neo_id)
    end
    tx_methods :load_node

    # Same as load but does not return the node as a wrapped Ruby object.
    #
    def _load_node(neo_id)
      return nil if neo_id.nil?
      @graph_db.get_node_by_id(neo_id.to_i)
    rescue Java::OrgNeo4jGraphdb.NotFoundException
      nil
    end

    def load_relationship(neo_id)
      _load_relationship(neo_id)
    end
    tx_methods :load_relationship

    def _load_relationship(neo_id)
      return nil if neo_id.nil?
      @graph_db.get_relationship_by_id(neo_id.to_i)
    rescue Java::OrgNeo4jGraphdb.NotFoundException
      nil
    end

    def query(*params)
      query_hash = @query_builder.to_query_hash(params, :to_node)
      cypher = @query_builder.to_cypher(query_hash)

      result = _query(cypher, query_hash[:params])
      if result.respond_to?(:error?) && result.error?
        raise Neo4j::Session::CypherError.new(result.error_msg, result.error_code, result.error_status)
      end

      map_return_procs = @query_builder.to_map_return_procs(query_hash)
      ResultWrapper.new(result, map_return_procs, cypher)
    end

    def find_all_nodes(label)
      EmbeddedLabel.new(self, label).find_nodes
    end

    def find_nodes(label, key, value)
      EmbeddedLabel.new(self, label).find_nodes(key,value)
    end

    # Performs a cypher query with given string.
    # Remember that you should close the resource iterator.
    # @param [String] q the cypher query as a String
    # @return (see #query)
    def _query(q, params={})
      @engine ||= Java::OrgNeo4jCypherJavacompat::ExecutionEngine.new(@graph_db)
      @engine.execute(q, Neo4j::Core::HashWithIndifferentAccess.new(params))
    rescue Exception => e
        raise Neo4j::Session::CypherError.new(e.message, e.class, 'cypher error')
    end

    def query_default_return(as)
      " RETURN #{as}"
    end

    def _query_or_fail(q)
      @engine ||= Java::OrgNeo4jCypherJavacompat::ExecutionEngine.new(@graph_db)
      @engine.execute(q)
    end

    def search_result_to_enumerable(result)
      result.map {|column| column['n'].wrapper}
    end

    def create_node(properties = nil, labels=[])
      if labels.empty?
        _java_node = graph_db.create_node
      else
        labels = EmbeddedLabel.as_java(labels)
        _java_node = graph_db.create_node(labels)
      end
      properties.each_pair { |k, v| _java_node[k]=v } if properties
      _java_node
    end
    tx_methods :create_node

  end



end