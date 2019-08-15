# encoding: UTF-8

Figaro.require_keys("sparkpost_password")

LANGUAGE_NAME = {
  cs: "Čeština", 
	ca: "Català",
  da: "Dansk",
  de: "Deutsch",
  el: "Ελληνικά",
  en: "English",  
  es: "Español", 
  fr: "Français",
  it: "Italiano", 
  nl: "Nederlands",
  pl: "Polski",
  pt: "Português",
	sl: "Slovenščina"
}

CORE_LANGUAGE_NAME = {
  de: "Deutsch",
  el: "Ελληνικά",
  en: "English",  
  es: "Español", 
  fr: "Français",
  it: "Italiano", 
  pt: "Português",
}

ALL_LANGUAGE_NAMES = LANGUAGE_NAME.values
ALL_LANGUAGE_CODES = LANGUAGE_NAME.keys.map(&:to_s)

LANGUAGE_CODE = LANGUAGE_NAME.invert  # works as a lookup method: LANGUAGE_CODE["Deutsch"] => "de"

NEWSLETTER_LANGUAGES = %w(English Français Deutsch Italiano Español Português Ελληνικά)

PRIVACY_POLICY_CODE = {
  de: "79786483",
	fr: "74383142",
	it: "30966858",
	es: "45303079",
	en: "49614846",
	else: "49614846"
}
PRIVACY_POLICY_CODE.default = "49614846"

# user.verification_state possible values
VERIFIED_NONE = 0
VERIFIED_EMAIL = 1
VERIFIED_ADDRESS = 2
VERIFIED_PHONE = 3
VERIFIED_IDENTITY = 4

VOLUNTEER_ABILITIES = ["translate", "transcribe", "social_media", "graphics", "editing_video", "producing_video",
  "writing", "events", "coding", "fundraise", "plan_coordinate", "manage_team", "leaflet", "data_entry"]
	

PAYPAL_STATUS = "working"

# Countries
ISO3166::Data.register(
  alpha2: 'mk',
  name: 'North Macedonia',
	translations: {
    'en' => 'North Macedonia',
    'de' => 'Nordmazedonien',
		'el' => 'Βόρεια Μακεδονία'
  }
)

ISO3166::Data.register(
  alpha2: 'xk',
  name: 'Kosovo',
)