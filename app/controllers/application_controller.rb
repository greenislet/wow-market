class ApplicationController < ActionController::Base
  def initialize
    @locale = "en_US"
    super
  end

  def locales_convert
    return {
      "en": "en_US",
      "es": "es_MX",
      "pt": "pt_BR",
      "fr": "fr_FR",
      "ru": "ru_RU",
      "it": "it_IT",
      "ko": "ko_KR",
      "zh": "zh_TW",
    }
  end

  helper_method :locale_to_language

  def locale_to_language
    return {
      "en_US": "English",
      "es_MX": "Español",
      "pt_BR": "Português Brasileiro",
      "fr_FR": "Francais",
      "ru_RU": "Русский",
      "it_IT": "Italiano",
      "ko_KR": "한국어",
      "zh_TW": "简体中文",
    }
  end

  helper_method :locale_idx

  def locale_idx
    return {
      "en_US": 0,
      "es_MX": 1,
      "pt_BR": 2,
      "fr_FR": 3,
      "ru_RU": 4,
      "it_IT": 5,
      "ko_KR": 6,
      "zh_TW": 7,
    }
  end

  helper_method :languages

  def languages
    languages = []
    stored_locales = RealmName.select(:locale).group(:locale)
    locale_to_language.each do |loc, lang|
      stored_locales.each do |record|
        if record[:locale] == loc.to_s
          languages << lang
        end
      end
    end
    return languages
  end


  around_action :switch_locale

  def switch_locale(&action)
    if session[:locale].nil?
      session[:locale] = "en_US"
    end

    if !params[:lang].nil?
      session[:locale] = locales_convert[params[:lang].to_sym]
      if session[:locale].nil?
        session[:locale] = "en_US"
      end
    end

    @locale = session[:locale]
    I18n.locale = locales_convert.key(@locale).to_s
    action.call
  end

end
