module RPN
  class Evaluator
    attr_accessor :stack

    def initialize;@stack=[] end
    def push(x) @stack<<x end
    def pop;@stack.pop end
    def tip;@stack[-1] end

    def top(num=1)
      return [] if num<1
      @stack[-num.to_i..-1]
    end

    def drop(num=1)
      return [] if num<1
      @stack=@stack[0..-num.to_i-1]
    end

    def method_eval(method)
        result=method.call(*top(method.arity.abs))
        drop method.arity.abs
        push result
    end

    def token_eval(token)
      if token=~/\A-?[0-9]+\.[0-9]+\Z/
        push token.to_f
      elsif token=~/\A-?[0-9]+\Z/
        push token.to_i
      elsif token=="$" or token == "dup"
        push tip
      elsif token  =="flat"
        pop.each do |x| push x end
      elsif token=="#" or token  =="pack"
        num=pop.to_i
        ar=top num
        drop num
        push ar
      elsif tip.respond_to? token
        method_eval pop.method token
      elsif Math.respond_to? token
        method_eval Math.method token
      else
        raise "unkonwn token #{token}"
      end
    end

    def run(string)
      res=""
      tokens=string.split " "
      tokens.each do  |token|
        token_eval(token)
        res=@stack.inspect+"\n"
      end
      return res
    end

  end
end

#eve=Evaluator.new
#while gets
# print eve.run($_)
#end
