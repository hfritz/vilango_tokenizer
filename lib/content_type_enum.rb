class ContentTypeEnum < ActiveEnum::Base
    value :id => 1, :name => 'word'
    value :id => 2, :name => 'break'
    value :id => 3, :name => 'punctuation'
    value :id => 4, :name => 'na'
    value :id => 5, :name => 'too_many_matches'
    value :id => 6, :name => 'pause'
    value :id => 7, :name => 'placeholder'
    
    def self.to_edit_token_select
      ret = []
      
      word = []
      word << ContentTypeEnum[ContentTypeEnum[:word]]
      word << ContentTypeEnum[:word]

      punct = []
      punct << ContentTypeEnum[ContentTypeEnum[:punctuation]]
      punct << ContentTypeEnum[:punctuation]
      
      ret << word
      ret << punct
      
      return ret
    end
end
