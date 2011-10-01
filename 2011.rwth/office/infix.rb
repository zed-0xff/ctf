module INFIX
	class Evaluator

    class String
        def tokenize(tokens) #for later use
            string=self.clone
            matches=[]
            while string.length!=0
                tokenized = tokens.map do |name,regexp|
                        if (string=~regexp)==0
                            if $& then [name,$&,$'] else nil end 
                        end 
                    end 
                name,match,string =tokenized.compact.max_by{|x| x[1].length}
                return nil unless match
                matches<<[name,match]
            end 
            return matches
        end 
    end 

		def run(string)
			string.strip!
			if string=~/^[+*\/%-()0-9]*$/ #whitelist math expressions
				return eval(string).to_s
			end
			return "not a math expression (you may not use anything but numbers and operators)"
		end
	end
end
