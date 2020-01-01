# =====================================================================================================
# This rake task helps to reuse already translated strings from Rails' *.yml into Ember's *.json files
#
# Author: Vignesh Kumar
#
# Idea:
# Whenever reusing values from existing *.yml key is needed, *.json (/frontend/translations/) will have
# to specify the complete key path of the existing translated string from its corresponding *.yml file,
# as the value, with delimiter for each level.

# File setup:
# locale = 'en', delimiter='##'
# config/locales/itil/en.yml    --> 'en.application_errors.bad_request': 'Bad Request'
# frontend/translations/en.json --> 'fs.common.app_errors.warning':'application_errors##bad_request'
#
# Supported locales :
# :ar, :ca, :cs, :"cy-GB", :da, :de, :en, :es, :"es-LA", :et, :fi, :fr, :he, :hu, :id, :it,
# :"ja-JP", :ko, :"nb-NO", :nl, :pl, :"pt-BR", :"pt-PT", :ro, :"ru-RU", :sk, :sl, :"sv-SE",
# :th, :tr, :vi, :"zh-CN", :"zh-TW"
#
# Invocation:
# rake frontend_chores:copy_keys		    --> runs both sub-tasks
# rake frontend_chores:copy_keys['ar']  --> invokes both sub-tasks with 'ar' param
# 	(step 1 --> rake frontend_chores:copy_delimited_values)
# 	(step 2 --> rake frontend_chores:copy_i18n_values)
#
# ======================================================================================================

namespace :frontend_chores do

	# Default task
	task :copy_keys => [:copy_delimited_values, :copy_i18n_values]

	###################################################################################################
	desc "Copies keys specified with delimiter(##) values from '/frontend/translations/en.json' file
into all non-en json files"
	###################################################################################################
	# Invocation:
	# rake frontend_chores:copy_delimited_values						---> copies delimited values from en.json to all *.json
	# rake frontend_chores:copy_delimited_values['ar','es']	---> copies delimited values from en.json to ar.json,es.json only
	task :copy_delimited_values => :environment do |task, args|
		args_arr = args.to_a
		copy_src_locale = :en
		copy_target_locales = args_arr.empty? ? (all_locales - [:en]) : args_arr

		begin_delimited_values_copy(copy_src_locale, copy_target_locales)
	end

	###################################################################################################
	desc "Copies existing translation strings from 'config/locales/itil/*.yml' into
'/frontend/translations/*.json'based on the keys specified with delimiter"
	###################################################################################################
	# Invocation:
	# rake frontend_chores:copy_i18n_values                     ---> runs for all 32 locales
	# rake frontend_chores:copy_i18n_values[en]                 ---> runs for 'en' locale only
	# rake frontend_chores:copy_i18n_values['en']
	# rake frontend_chores:copy_i18n_values[ar,es,pt-BR]        ---> runs for 'ar', 'es', 'pt-BR' locales only (no space b/w values)
	task :copy_i18n_values => :environment do |task, args|
		args_arr = args.to_a
		locales = args_arr.empty? ? all_locales : args_arr

		begin_i18n_values_copy(locales)
	end

	private

	def begin_delimited_values_copy(copy_src_locale, copy_target_locales)

		#1. Read the source json ('en') file
		src_data = read_json_file(copy_src_locale)
		en_file_path = src_data[0]
		en_file_data = src_data[1]

		#2. Flatten source ('en') json data
		en_flat_hash = flatten_data_hash(en_file_data)

		#3. Find keys with delimiter values
		delimiter = "##"
		en_delimited_kv_pairs = {}
		en_flat_hash.each do |key, value|
			if value.include?(delimiter)
				en_delimited_kv_pairs[key] = value
			end
		end

		#4. Read target json file(s)
		t_start = Time.now
		puts "\n====== Task 1 : frontend_chores:copy_delimited_values ======"
		puts "\n Copying delimited values from #{copy_src_locale.to_s}.json to *.json : #{copy_target_locales}"

		copy_target_locales.each do |copy_target_locale|
			begin
				puts "\n Copying : #{copy_src_locale.to_s}.json --> #{copy_target_locale.to_s}.json"

				begin_delimited_values_copy_per_locale(en_delimited_kv_pairs, copy_target_locale)
			rescue => e
				Rails.logger.info "Exception occurred :::::: \n #{e.message} \n #{e.backtrace.join("\n")}"
			else
				puts " Done !"
			end
		end

		t_end = Time.now
		elapsed_time_ms = ((t_end - t_start) * 1000).round(2)
		puts "\n================== Time elapsed: #{elapsed_time_ms}ms =================="
	end

	def begin_delimited_values_copy_per_locale(en_delimited_kv_pairs, copy_target_locale)
		target_data = read_json_file(copy_target_locale)
		target_file_path = target_data[0]
		target_file_data = target_data[1]

		# Flatten target json data
		target_flat_hash = {}
		target_flat_hash = flatten_data_hash(target_file_data) if target_file_data.present?

		# Merge delimited value keys from src (en) json data into target json data
		result = target_flat_hash.merge(en_delimited_kv_pairs)

		# Unflatten target json data
		unflattened_hash = unflatten_data_hash(result)

		# Write to target file
		write_json_file(target_file_path, unflattened_hash)
	end

	def begin_i18n_values_copy(locales)
		t_start = Time.now
		puts "\n========= Task 2 : frontend_chores:copy_i18n_keys ========="
		puts "\n Copying values from *.yml to corresponding *.json : #{locales}"

		locales.each do |locale|
			begin
				puts "\n Copying : #{locale.to_s}.yml --> #{locale.to_s}.json"

				begin_i18n_values_copy_per_locale(locale)
			rescue => e
				Rails.logger.info "Exception occurred :::::: \n #{e.message} \n #{e.backtrace.join("\n")}"
			else
				puts " Done !"
			end
		end

		t_end = Time.now
		elapsed_time_ms = ((t_end - t_start) * 1000).round(2)
		puts "\n================== Time elapsed: #{elapsed_time_ms}ms =================="
	end

	def begin_i18n_values_copy_per_locale(locale)
		I18n.locale = locale.to_sym

		data = read_json_file(locale)
		flat_hash = {}
		file_path = data[0]
		file_data = data[1]

		flat_hash = flatten_data_hash(file_data) if file_data.present?
		result = replace_delimiter(flat_hash)
		unflattened_hash = unflatten_data_hash(result)
		write_json_file(file_path, unflattened_hash)

		I18n.locale = :en
	end

	# Reads the given locale *.json file (creates a new file if not existing)
	def read_json_file(locale)
		ember_json_file_path = File.join(Rails.root, "frontend", "translations", "#{locale.to_sym}.json")
		file_exists = File.exist?(ember_json_file_path)
		if file_exists # Read file contents, if file exists.
			file_contents = File.read(ember_json_file_path)
			ember_json_file_data = JSON.parse(file_contents)
		else # Create the locale file, if file doesn't exist
			file_handle = File.new(ember_json_file_path, "w")
			ember_json_file_data = File.read(file_handle)
		end
		return [ember_json_file_path, ember_json_file_data]
	end

	# Flattens all the nested level for easier access
	def flatten_data_hash(ember_json_file_data)
		flatten_hash(ember_json_file_data)
	end

	# Iterates the json file data to find the delimiters and replace them with equivalent values from *.yml in place.
	def replace_delimiter(flat_json_data_hash)
		delimiter = "##"
		flat_json_data_hash.each do |key, value|
			if value.include?(delimiter)
				value = I18n.t(value.gsub! delimiter, '.')
				flat_json_data_hash[key] = value
			end
		end
		return flat_json_data_hash
	end

	# Unflattens the nested keys
	def unflatten_data_hash(flat_json_data_hash)
		new_hash = unflatten_hash(flat_json_data_hash)
		new_hash.deep_stringify_keys!
	end

	# Updates the *.json file with the formatted json
	def write_json_file(ember_json_file_name, new_hash)
		File.open(ember_json_file_name, 'w') do |file|
			formatted = JSON.pretty_generate(new_hash, :indent => "\t")
			file.write(formatted)
		end
	end

	# Common utilities

	def all_locales
		I18n.available_locales
	end

	def flatten_hash(param, prefix = nil)
		param.each_pair.reduce({}) do |a, (k, v)|
			v.is_a?(Hash) ? a.merge(flatten_hash(v, "#{prefix}#{k}.")) : a.merge("#{prefix}#{k}".to_sym => v)
		end
	end

	def unflatten_hash(param)
		param.map do |pkey, pvalue|
			pkey.to_s.split(".").reverse.inject(pvalue) do |value, key|
				{key.to_sym => value}
			end
		end.inject(&:deep_merge)
	end
end
