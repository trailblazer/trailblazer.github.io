step Rescue( RecordNotFound, handler: :rollback! ) {
    step Wrap ->(*, &block) { Sequel.transaction do block.call end } {
      step Model( Song, :find )
      step ->(options) { options["model"].lock! } # lock the model.
      step Contract::Build( constant: MyContract )
      step Contract::Validate( )
      step Contract::Persist( method: :sync )
    }
  }
  failure :error
