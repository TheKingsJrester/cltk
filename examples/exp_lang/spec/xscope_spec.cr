require "spec"
require "../xscope"
require "../xast"

describe "EXP_LANG::Scope" do
  context "simple operations" do
    scope = EXP_LANG::Scope(String).new

    it "can be initialized" do
      scope.class.should eq EXP_LANG::Scope(String)
    end

    it "can inherit a child of itself" do
      scope.inherit.parent.should eq scope
    end

    it "can set a key to a value" do
      scope.set("name", "root").should eq("root")
    end

    it "can get a value for a key" do
      scope.get("name").should eq "root"
    end

    it "returns undefined if a key is not set" do
      scope.get("noname").should eq EXP_LANG::Undefined
    end

    describe "#clone" do
      scope = EXP_LANG::Scope(String).new
      scope["name"] = "first"
      scope["age"] = "twelve"

      it "can clone itself" do
        scope.clone.should_not eq scope
      end

      it "will clone all the values" do
        scope.clone["name"].should eq "first"
        scope.clone["age"].should eq "twelve"
      end
    end
  end
  context "recursive lookups" do
    parent = EXP_LANG::Scope(String).new
    parent["name"] = "parent"
    scope = EXP_LANG::Scope(String).new(parent)

    it "holds a reference to its parent" do
      scope.parent.should eq parent
    end

    it "returns parents values if not overloaded" do
      scope["name"].should eq("parent")
    end

    it "overloads parents values" do
      scope["name"] = "child"
      scope["name"].should eq("child")
    end

    it "can free values" do
      scope["name"] = "child"
      scope.delete("name")
      scope["name"].should eq("parent")
    end
  end

  context "more complex types (ASTNode)" do
    parent = EXP_LANG::Scope(Expression).new
    parent["n"] = ANumber.new(value: 2.to_f)
    scope = EXP_LANG::Scope(Expression).new(parent)

    it "holds a reference to its parent" do
      scope.parent.should eq parent
    end

    it "can set a key to a value" do
      scope.set("n", ANumber.new(value: 2.to_f)).should eq(ANumber.new(value: 2.to_f))
    end

    it "can get a value for a key" do
      scope.get("n").should eq ANumber.new(value: 2.to_f)
    end

    it "returns undefined if a key is not set" do
      scope.get("noname").should eq EXP_LANG::Undefined
    end
  end

  context "evaluation of expressions in scope" do
    scope = EXP_LANG::Scope(Expression).new

    it "should eval a simple variable identifier to its expression" do
      scope["x"] = ANumber.new(value: 2.to_f)
      scope.eval(Variable.new(name: "x")).should eq ANumber.new(value: 2.to_f)
    end
  end
end
