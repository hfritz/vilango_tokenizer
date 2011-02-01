class PunctuationLayoutEnum < ActiveEnum::Base
  value :id => 1, :name => 'pre'
  value :id => 2, :name => 'post'
  value :id => 3, :name => 'both'
        
  def self.to_translated_select
    ret = []

    pre = []
    pre << I18n.t('enumerable.pre')
    pre << PunctuationLayoutEnum[:pre]

    post = []
    post << I18n.t('enumerable.post')
    post << PunctuationLayoutEnum[:post]

    both = []
    both << I18n.t('enumerable.both')
    both << PunctuationLayoutEnum[:both]

    ret << pre
    ret << post
    ret << both

    return ret
  end      
    
end
