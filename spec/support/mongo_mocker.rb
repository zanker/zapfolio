module MongoMocker
  module Finders
    def mock_finder(model, id=model._id.to_s)
      model.class.should_receive(:find).with(id).once.ordered.and_return(model)
    end

    def mock_where_finder(model, id=model._id.to_s)
      first = mock("CriteriaFirst")
      first.should_receive(:first).and_return(model)

      criteria = mock("Criteria")
      criteria.stub(:only).and_return(first)
      criteria.stub(:first).and_return(model)

      model.class.should_receive(:where).with(:_id => id).once.ordered.and_return(criteria)
    end
  end
end