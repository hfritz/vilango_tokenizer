module VilangoTokenizer
  def self.included(base)
    base.extend ClassMethods
  end
  
  module ClassMethods
    ASIEN_LANGUAGE_LIST = [
      'zh',
      'ar',
      'as',
      'bh',
      'bn',
      'bo',
      'dz',
      'et',
      'fa',
      'gu',
      'ha',
      'hi',
      'iu',
      'ja',
      'jw',
      'km',
      'kn',
      'ko',
      'ks',
      'ku',
      'lo',
      'ml',
      'mn',
      'ms',
      'my',
      'na',
      'ne',
      'or',
      'pa',
      'ps',
      'sa',
      'sd',
      'si',
      'ta',
      'te',
      'th',
      'ti',
      'tl',
      'ug',
      'ur',
      'vi',
      'za'
      ].freeze

      class TokenRegexClass
        attr_accessor :type, :regex

        def initialize(type, regex)
          @type = type
          @regex = regex
        end
      end

      class LatinTokenPatternMatcher
        WORD_PATTERN = /(?!¡)*(?!¿)*\w+/
        PUNCTUATION_PATTERN = /[¿|¡|[:punct:]]+/
        BREAK_PATTERN = /\r\n|\n|\r/

        WORD_MATCHER =  TokenRegexClass.new( ContentTypeEnum[:word], /(#{WORD_PATTERN})/)
        PUNCTUATION_MATCHER =  TokenRegexClass.new( ContentTypeEnum[:punctuation], /(#{PUNCTUATION_PATTERN})/)
        BREAK_MATCHER =  TokenRegexClass.new( ContentTypeEnum[:break], /(#{BREAK_PATTERN})/)    

        PATTERN = /(#{PUNCTUATION_PATTERN}|#{WORD_PATTERN}|#{BREAK_PATTERN})/
      end

      class ChineseTokenPatternMatcher
        PUNCT_STRING = "\'|\"|!|\?|？|！|，|、|；|：|（|）|【|】|［|］|。|「|」|﹁|﹂|“|”|·|.|《|》|〈|〉|…|—|～|\(|\)|）|（"
        PUNCTUATION_PATTERN = "[#{PUNCT_STRING}]+"
        IGNORE_PATTERN = / \t/

        BREAK_PATTERN = TokenizeHelper::LatinTokenPatternMatcher::BREAK_PATTERN
        WORD_PATTERN = "[^#{PUNCT_STRING}|#{BREAK_PATTERN}|#{IGNORE_PATTERN}]"

        WORD_MATCHER =  TokenRegexClass.new( ContentTypeEnum[:word], /(#{WORD_PATTERN})/)
        PUNCTUATION_MATCHER =  TokenRegexClass.new( ContentTypeEnum[:punctuation], /(#{PUNCTUATION_PATTERN})/)
        BREAK_MATCHER =  TokenRegexClass.new( ContentTypeEnum[:break], /(#{BREAK_PATTERN})/)    

        PATTERN = /(#{PUNCTUATION_PATTERN}|#{BREAK_PATTERN}|#{WORD_PATTERN})/
      end

      def self.create_item_array(text, pattern_matcher)
        arr = text.scan(pattern_matcher::PATTERN)
        arr.flatten!
      end

      def self.findCorrectPatternMatcher(language_code)
        if(ASIEN_LANGUAGE_LIST.include? language_code)
          return ChineseTokenPatternMatcher
        else
          return LatinTokenPatternMatcher
        end
      end


      def self.contains_punctuations?(text, language_code)
        matcher = findCorrectPatternMatcher(language_code)
        found = text.scan(/(^#{matcher::PUNCTUATION_PATTERN})/).to_s

        return !found.blank?
      end

      def self.get_start_punctuation_token(text, language_code)
        matcher = findCorrectPatternMatcher(language_code)
        return get_punctuation_token(text, language_code, /(^#{matcher::PUNCTUATION_PATTERN})/)
      end

      def self.get_end_punctuation_token(text, language_code)
        matcher = findCorrectPatternMatcher(language_code)
        return get_punctuation_token(text, language_code, /(#{matcher::PUNCTUATION_PATTERN}$)/)
      end

      def self.get_punctuation_token(text, language_code, pattern)
        cont = text.scan(pattern).to_s
        t = Token.new({:content => cont, :content_type => ContentTypeEnum[:punctuation]}) unless cont.empty?
        return t
      end

    def self.tokenize(transcript_id, text, language_code)
      slugs = transcript_text_text_to_xml(text, language_code, false)

      # add the transcript
      slugs.each{|s|
        s.transcript_id = transcript_id
        s.dialog_texts.each{|dt|
          dt.tokens.each{|t|
            t.transcript_id = transcript_id
          }
          dt.characters.each{|c|
            c.transcript_id = transcript_id
          }
        }
      }
      slugs.each{|s| s.valid?}

      slugs.each{|s|
        apply_quotation_mark_rules s
        if language_code == "fr"
          apply_french_accent_rules s
        end
      }

      slugs.each{|s| s.save}

    end

    def self.apply_french_accent_rules(slug)
      slug.dialog_texts.each{|dt|
        dt.tokens.each{|t|
          if t.content == "'"
            t.punctuation_layout = PunctuationLayoutEnum[:both]
          end
        }
      }
    end

    def self.apply_quotation_mark_rules(slug)
      found_first_quotation_mark = false
      slug.dialog_texts.each{|dt|
        dt.tokens.each{|t|
          if t.content == "\""
            if !found_first_quotation_mark
              t.punctuation_layout = PunctuationLayoutEnum[:pre]
              found_first_quotation_mark = true
            else
              found_first_quotation_mark = false
            end
          end
        }
      }
    end


      def self.tokenize_part_of_text(text, language_code, cur_init_token_pos)
        token_arr = []
        cur_pos = cur_init_token_pos

        matcher = findCorrectPatternMatcher(language_code)

        item_arr = create_item_array(text, matcher)
        last_token = nil
        item_arr.each_with_index {|item, index|
          type = typeoftoken(item, matcher)
          if type == ContentTypeEnum[:break]
            item = ""
          end
          cur_token = Token.new({:content => item, :content_type => type, :position => cur_pos})
          set_punctuation_layout(cur_token) if ContentTypeEnum[cur_token.content_type] == ContentTypeEnum[:punctuation]

          token_arr << cur_token
          cur_pos = cur_pos+1
          #last_token = cur_token
        }
        return token_arr
      end

      def self.set_punctuation_layout(cur_token)
        if cur_token.content == "¡" || cur_token.content == "¿" || cur_token.content == "("
          cur_token.punctuation_layout = PunctuationLayoutEnum[:pre]
        elsif cur_token.content == "-"
          cur_token.punctuation_layout = PunctuationLayoutEnum[:both]
        else
          cur_token.punctuation_layout = PunctuationLayoutEnum[:post]
        end
      end

      def self.typeoftoken(token, pattern_matcher)  
        regs = [ pattern_matcher::PUNCTUATION_MATCHER, pattern_matcher::WORD_MATCHER, pattern_matcher::BREAK_MATCHER ]
        types = []
        regs.each{ |reg|
          cur = token.scan(reg.regex)
          if !cur.empty? 
            types << reg.type
          end
        }

        if types.size == 1
          return types.first
        elsif types.size > 1
          return ContentTypeEnum[:too_many_matches]
        else
          return ContentTypeEnum[:na]
        end
      end

      class TokenizationError < StandardError
      end

      class TemplatePatterns
        VariableStart               = /\{\{/
        VariableEnd                 = /\}\}/
        TemplateParser = /(#{VariableStart}.*?#{VariableEnd})/

        BracetParser = /(#{VariableStart}|#{VariableEnd})/

        SLUG = "Slug|Scene|S"
        CHARACTER = "Character|C"

        SlugPattern       = /#{VariableStart}(#{SLUG})(?:: ?(.*))?#{VariableEnd}/
        CharacterPattern  = /#{VariableStart}(#{CHARACTER})(?:: ?(.*))?#{VariableEnd}/

        def self.create_slug_from_string(position, string_pattern)
          tags = string_pattern.scan(TokenizeHelper::TemplatePatterns::SlugPattern)
          raise TokenizeHelper::TokenizationError, "Passed string does not contain just one matched pattern but: #{tags.size}" unless tags.size == 1
          slug = Slug.new
          slug.position = position

          if !tags[0][1].nil?
            strings_arr = tags[0][1].split('|')
            if strings_arr.size == 1
              slug.location = strings_arr[0].lstrip.rstrip
            elsif strings_arr.size == 2
              slug.location = strings_arr[0].lstrip.rstrip
              slug.description = strings_arr[1].lstrip.rstrip
            else
              raise TokenizeHelper::TokenizationError, "Passed string contains more than one '|', but it should only contain one or none"
            end
          end

          return slug
        end

        def self.create_character_from_string(string_pattern)
          tags = string_pattern.scan(TokenizeHelper::TemplatePatterns::CharacterPattern)
          raise TokenizeHelper::TokenizationError, "Passed string does not contain just one matched pattern but: #{tags.size}" unless tags.size == 1

          characters = []

          if !tags[0][1].nil?
            tags[0][1].split(/,|，/).each{|cur_char|
              characters << Character.new(:name => cur_char.rstrip.lstrip)
            }
          else
            raise TokenizeHelper::TokenizationError, "Passed string contains no names, but it should at least contain one!"
          end

          return characters
         end
      end

      def self.find_character_in_array_by_name(arr, name)
        arr.each{|cur|
          if cur.name == name
            return cur
          end
        }
        return nil
      end

      def self.transcript_text_text_to_xml(text, language_code, validate_only)
        tags = text.split(TokenizeHelper::TemplatePatterns::TemplateParser)
        tags.shift if tags[0] and tags[0].empty?

        cur_slug_position = 1
        cur_dialog_position = 1
        cur_tokens_string = ""
        cur_initial_token_position = 1
        cur_sorted_chars = []
        unique_characters = []
        cur_slug = nil
        slugs = []

        tags.each{|cur_tag|
          # what am I 
          case cur_tag
            when TemplatePatterns::SlugPattern:
              if !cur_slug.nil?
                # we have already something to process...
                raise TokenizeHelper::TokenizationError, "Slug[#{cur_tag}] can't exist without characters!" if cur_sorted_chars.empty?
                raise TokenizeHelper::TokenizationError, "Slug[#{cur_tag}] can't exist without tokens!" if cur_tokens_string.empty?

                cur_initial_token_position = create_dialog_text_helper(cur_slug, cur_sorted_chars, cur_dialog_position, cur_tokens_string, language_code, validate_only, cur_initial_token_position)

                slugs << cur_slug
                cur_sorted_chars = []
                cur_dialog_position = 1
                cur_tokens_string = ""
              end

              cur_slug = TokenizeHelper::TemplatePatterns.create_slug_from_string(cur_slug_position, cur_tag)
              cur_slug_position = cur_slug_position+1
            when TemplatePatterns::CharacterPattern:
              #puts " C-#{cur_tag}"
              raise TokenizeHelper::TokenizationError, "Characters[#{cur_tag}] can't exist without a slug!" if cur_slug.nil?

              if !cur_sorted_chars.empty?
                cur_initial_token_position = create_dialog_text_helper(cur_slug, cur_sorted_chars, cur_dialog_position, cur_tokens_string, language_code, validate_only, cur_initial_token_position)
                cur_dialog_position = cur_dialog_position +1
                cur_tokens_string = ""
              end
              cur_characters = TokenizeHelper::TemplatePatterns.create_character_from_string(cur_tag)
              cur_sorted_chars = []

              cur_characters.each{|cur_parsed_char|
                found_char = find_character_in_array_by_name(unique_characters, cur_parsed_char.name)
                if found_char.nil?
                  cur_sorted_chars<<cur_parsed_char
                  unique_characters<<cur_parsed_char
                else
                  cur_sorted_chars<<found_char
                end
              }

            else
              #puts "  N-#{cur_tag}"
              next if cur_tag.lstrip.rstrip.empty?
              # "[#{cur_slug_position-1}|#{cur_dialog_position-1}] Tokens[#{cur_tag}|#{cur_sorted_chars}] can't exist without a slug!" if cur_slug.nil?
              raise TokenizeHelper::TokenizationError, "Text can't exist without a slug!   #{cur_tag}" if cur_slug.nil?
              raise TokenizeHelper::TokenizationError, "Text can't exist without a character!   #{cur_tag}" if cur_sorted_chars.empty?
              raise TokenizeHelper::TokenizationError, "Text can't contain {{ or }}!   #{cur_tag}" if cur_tag.scan(TokenizeHelper::TemplatePatterns::BracetParser).size > 0

              # We got just the text :)
              cur_tokens_string = cur_tokens_string + cur_tag
          end
        }
        ## add last slug
        raise TokenizeHelper::TokenizationError, "Last slug can't exist without characters!" if cur_sorted_chars.empty?
        raise TokenizeHelper::TokenizationError, "Last slug can't exist without tokens!" if cur_tokens_string.empty?

        create_dialog_text_helper(cur_slug, cur_sorted_chars, cur_dialog_position, cur_tokens_string, language_code, validate_only, cur_initial_token_position)
        slugs << cur_slug

        return slugs
      end

      def self.create_dialog_text_helper(cur_slug, cur_characters, cur_dialog_position, cur_tokens_string, language_code, validate_only, start_pos)
        tmp_dialog_text = DialogText.new({:slug => cur_slug, :position => cur_dialog_position, :action => ""})
        cur_characters.each{|c|
          tmp_dialog_text.characters << c
        }

        tmp_dialog_text.tokens = tokenize_part_of_text(cur_tokens_string.rstrip.lstrip, language_code, start_pos) if !validate_only
        cur_slug.dialog_texts << tmp_dialog_text
        return start_pos + tmp_dialog_text.tokens.size
      end

      def self.transcript_text_valid?(xml, language_code)
        begin
          transcript_text_text_to_xml(xml, language_code, true)
        rescue TokenizeHelper::TokenizationError
          return false
        end

        return true
      end

      def self.transcript_text_error(xml, language_code)
        begin
          transcript_text_text_to_xml(xml, language_code, true)
        rescue TokenizeHelper::TokenizationError => except

          return except.message if except.message.size < 60
          return except.message.slice(-59..-1)
        end
        return ""
      end
    
    
  end
end

class ActiveRecord::Base
  include VilangoTokenizer
end
