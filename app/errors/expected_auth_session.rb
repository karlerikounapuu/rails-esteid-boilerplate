module Errors
  class ExpectedAuthSession < StandardError
    attr_reader :provided_class, :message

    def initialize(provided_class = nil)
      @provided_class = provided_class.name
      @message = "Expected #{provided_class} to be a descendant of AuthSession."
      super(message)
    end
  end
end
