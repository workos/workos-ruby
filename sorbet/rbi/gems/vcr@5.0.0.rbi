# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `vcr` gem.
# Please instead update this file by running `bin/tapioca gem vcr`.

module VCR
  include ::VCR::VariableArgsBlockCaller
  include ::VCR::Errors
  extend ::VCR::VariableArgsBlockCaller
  extend ::VCR::Errors
  extend ::VCR

  def cassette_persisters; end
  def cassette_serializers; end
  def cassettes(context = T.unsafe(nil)); end
  def config; end
  def configuration; end
  def configure; end
  def cucumber_tags(&block); end
  def current_cassette; end
  def eject_cassette(options = T.unsafe(nil)); end
  def fibers_available?; end
  def http_interactions; end
  def insert_cassette(name, options = T.unsafe(nil)); end
  def library_hooks; end
  def link_context(from_thread, to_key); end
  def real_http_connections_allowed?; end
  def record_http_interaction(interaction); end
  def request_ignorer; end
  def request_matchers; end
  def turn_off!(options = T.unsafe(nil)); end
  def turn_on!; end
  def turned_off(options = T.unsafe(nil)); end
  def turned_on?; end
  def unlink_context(key); end
  def use_cassette(name, options = T.unsafe(nil), &block); end
  def use_cassettes(cassettes, &block); end
  def version; end

  private

  def context_cassettes; end
  def context_value(name); end
  def current_context; end
  def dup_context(context); end
  def get_context(thread_key, fiber_key = T.unsafe(nil)); end
  def ignore_cassettes?; end
  def initialize_fibers; end
  def initialize_ivars; end
  def set_context_value(name, value); end

  class << self
    def const_missing(const); end
  end
end

class VCR::Cassette
  include ::VCR::Logger::Mixin

  def initialize(name, options = T.unsafe(nil)); end

  def clean_outdated_http_interactions; end
  def eject(options = T.unsafe(nil)); end
  def erb; end
  def file; end
  def http_interactions; end
  def linked?; end
  def match_requests_on; end
  def name; end
  def new_recorded_interactions; end
  def originally_recorded_at; end
  def re_record_interval; end
  def record_http_interaction(interaction); end
  def record_mode; end
  def recording?; end
  def serializable_hash; end
  def tags; end

  private

  def assert_valid_options!; end
  def assign_tags; end
  def deserialized_hash; end
  def extract_options; end
  def interactions_to_record; end
  def invoke_hook(type, interactions); end
  def log_prefix; end
  def merged_interactions; end
  def previously_recorded_interactions; end
  def raise_error_unless_valid_record_mode; end
  def raw_cassette_bytes; end
  def request_summary(request); end
  def should_assert_no_unused_interactions?; end
  def should_re_record?; end
  def should_remove_matching_existing_interactions?; end
  def should_stub_requests?; end
  def storage_key; end
  def up_to_date_interactions(interactions); end
  def write_recorded_interactions_to_disk; end

  class << self
    def const_missing(const); end
  end
end

class VCR::Cassette::ERBRenderer
  def initialize(raw_template, erb, cassette_name = T.unsafe(nil)); end

  def render; end

  private

  def binding_for_variables; end
  def erb_variables; end
  def handle_name_error(e); end
  def template; end
  def use_erb?; end
  def variables_object; end
end

module VCR::Cassette::EncodingErrorHandling
  def handle_encoding_errors; end
end

class VCR::Cassette::HTTPInteractionList
  include ::VCR::Logger::Mixin

  def initialize(interactions, request_matchers, allow_playback_repeats = T.unsafe(nil), parent_list = T.unsafe(nil), log_prefix = T.unsafe(nil)); end

  def allow_playback_repeats; end
  def assert_no_unused_interactions!; end
  def has_interaction_matching?(request); end
  def has_used_interaction_matching?(request); end
  def interactions; end
  def parent_list; end
  def remaining_unused_interaction_count; end
  def request_matchers; end
  def response_for(request); end

  private

  def has_unused_interactions?; end
  def interaction_matches_request?(request, interaction); end
  def log_prefix; end
  def matching_interaction_index_for(request); end
  def matching_used_interaction_for(request); end
  def request_summary(request); end
end

module VCR::Cassette::HTTPInteractionList::NullList
  extend ::VCR::Cassette::HTTPInteractionList::NullList

  def has_interaction_matching?(*a); end
  def has_used_interaction_matching?(*a); end
  def remaining_unused_interaction_count(*a); end
  def response_for(*a); end
end

class VCR::Cassette::Persisters
  def initialize; end

  def [](name); end
  def []=(name, value); end
end

module VCR::Cassette::Persisters::FileSystem
  extend ::VCR::Cassette::Persisters::FileSystem

  def [](file_name); end
  def []=(file_name, content); end
  def absolute_path_to_file(file_name); end
  def storage_location; end
  def storage_location=(dir); end

  private

  def absolute_path_for(path); end
  def sanitized_file_name_from(file_name); end
end

class VCR::Cassette::Serializers
  def initialize; end

  def [](name); end
  def []=(name, value); end
end

module VCR::Cassette::Serializers::Compressed
  extend ::VCR::Cassette::Serializers::Compressed

  def deserialize(string); end
  def file_extension; end
  def serialize(hash); end
end

module VCR::Cassette::Serializers::Psych
  extend ::VCR::Cassette::Serializers::Psych
  extend ::VCR::Cassette::EncodingErrorHandling

  def deserialize(string); end
  def file_extension; end
  def serialize(hash); end
end

VCR::Cassette::Serializers::Psych::ENCODING_ERRORS = T.let(T.unsafe(nil), Array)

module VCR::Cassette::Serializers::Syck
  extend ::VCR::Cassette::Serializers::Syck
  extend ::VCR::Cassette::EncodingErrorHandling

  def deserialize(string); end
  def file_extension; end
  def serialize(hash); end

  private

  def using_syck; end
end

VCR::Cassette::Serializers::Syck::ENCODING_ERRORS = T.let(T.unsafe(nil), Array)

module VCR::Cassette::Serializers::YAML
  extend ::VCR::Cassette::Serializers::YAML
  extend ::VCR::Cassette::EncodingErrorHandling

  def deserialize(string); end
  def file_extension; end
  def serialize(hash); end
end

VCR::Cassette::Serializers::YAML::ENCODING_ERRORS = T.let(T.unsafe(nil), Array)
VCR::Cassette::VALID_RECORD_MODES = T.let(T.unsafe(nil), Array)
VCR::CassetteMutex = T.let(T.unsafe(nil), Thread::Mutex)

class VCR::Configuration
  include ::VCR::VariableArgsBlockCaller
  include ::VCR::Hooks
  include ::VCR::Configuration::DefinedHooks
  include ::VCR::Logger::Mixin
  extend ::VCR::Hooks::ClassMethods

  def initialize; end

  def after_http_request(*filters); end
  def allow_http_connections_when_no_cassette=(_arg0); end
  def allow_http_connections_when_no_cassette?; end
  def around_http_request(*filters, &block); end
  def before_playback(tag = T.unsafe(nil), &block); end
  def before_record(tag = T.unsafe(nil), &block); end
  def cassette_library_dir; end
  def cassette_library_dir=(dir); end
  def cassette_persisters; end
  def cassette_serializers; end
  def configure_rspec_metadata!; end
  def debug_logger; end
  def debug_logger=(value); end
  def default_cassette_options; end
  def default_cassette_options=(overrides); end
  def define_cassette_placeholder(placeholder, tag = T.unsafe(nil), &block); end
  def filter_sensitive_data(placeholder, tag = T.unsafe(nil), &block); end
  def hook_into(*hooks); end
  def ignore_host(*hosts); end
  def ignore_hosts(*hosts); end
  def ignore_localhost=(value); end
  def ignore_request(&block); end
  def logger; end
  def preserve_exact_body_bytes_for?(http_message); end
  def query_parser; end
  def query_parser=(_arg0); end
  def register_request_matcher(name, &block); end
  def stub_with(*adapters); end
  def unignore_host(*hosts); end
  def unignore_hosts(*hosts); end
  def uri_parser; end
  def uri_parser=(_arg0); end

  private

  def create_fiber_for(fiber_errors, hook_declaration, proc); end
  def load_library_hook(hook); end
  def log_prefix; end
  def register_built_in_hooks; end
  def request_filter_from(object); end
  def resume_fiber(fiber, fiber_errors, response, hook_declaration); end
  def start_new_fiber_for(request, fibers, fiber_errors, hook_declaration, proc); end
  def tag_filter_from(tag); end
end

module VCR::Configuration::DefinedHooks
  def after_http_request(*filters, &hook); end
  def after_library_hooks_loaded(*filters, &hook); end
  def before_http_request(*filters, &hook); end
  def before_playback(*filters, &hook); end
  def before_record(*filters, &hook); end
  def preserve_exact_body_bytes(*filters, &hook); end
end

class VCR::CucumberTags
  def initialize(main_object); end

  def tag(*tag_names); end
  def tags(*tag_names); end

  class << self
    def add_tag(tag); end
    def tags; end
  end
end

class VCR::CucumberTags::ScenarioNameBuilder
  def initialize(test_case); end

  def cassette_name; end
  def examples_table(*_arg0); end
  def examples_table_row(row); end
  def feature(feature); end
  def scenario(*_arg0); end
  def scenario_outline(feature); end
end

module VCR::Deprecations; end
module VCR::Deprecations::Middleware; end

module VCR::Deprecations::Middleware::Faraday
  def initialize(*args); end
end

module VCR::Errors; end
class VCR::Errors::AroundHTTPRequestHookError < ::VCR::Errors::Error; end
class VCR::Errors::CassetteInUseError < ::VCR::Errors::Error; end
class VCR::Errors::EjectLinkedCassetteError < ::VCR::Errors::Error; end
class VCR::Errors::Error < ::StandardError; end
class VCR::Errors::InvalidCassetteFormatError < ::VCR::Errors::Error; end
class VCR::Errors::LibraryVersionTooLowError < ::VCR::Errors::Error; end
class VCR::Errors::MissingERBVariableError < ::VCR::Errors::Error; end
class VCR::Errors::NotSupportedError < ::VCR::Errors::Error; end
class VCR::Errors::TurnedOffError < ::VCR::Errors::Error; end

class VCR::Errors::UnhandledHTTPRequestError < ::VCR::Errors::Error
  def initialize(request); end

  def request; end

  private

  def cassettes_description; end
  def cassettes_list; end
  def construct_message; end
  def current_cassettes; end
  def current_matchers; end
  def format_bullet_point(lines, index); end
  def format_foot_note(url, index); end
  def formatted_headers; end
  def formatted_suggestions; end
  def has_used_interaction_matching?; end
  def match_request_on_body?; end
  def match_request_on_headers?; end
  def match_requests_on_suggestion; end
  def no_cassette_suggestions; end
  def record_mode_suggestion; end
  def relish_version_slug; end
  def request_description; end
  def suggestion_for(key); end
  def suggestions; end
end

VCR::Errors::UnhandledHTTPRequestError::ALL_SUGGESTIONS = T.let(T.unsafe(nil), Hash)
class VCR::Errors::UnknownContentEncodingError < ::VCR::Errors::Error; end
class VCR::Errors::UnregisteredMatcherError < ::VCR::Errors::Error; end
class VCR::Errors::UnusedHTTPInteractionError < ::VCR::Errors::Error; end

class VCR::HTTPInteraction < ::Struct
  def initialize(*args); end

  def hook_aware; end
  def to_hash; end

  class << self
    def from_hash(hash); end
  end
end

class VCR::HTTPInteraction::HookAware
  def initialize(http_interaction); end

  def filter!(text, replacement_text); end
  def ignore!; end
  def ignored?; end

  private

  def filter_hash!(hash, text, replacement_text); end
  def filter_object!(object, text, replacement_text); end
end

module VCR::Hooks
  include ::VCR::VariableArgsBlockCaller

  mixes_in_class_methods ::VCR::Hooks::ClassMethods

  def clear_hooks; end
  def has_hooks_for?(hook_type); end
  def hooks; end
  def invoke_hook(hook_type, *args); end

  class << self
    def included(klass); end
  end
end

module VCR::Hooks::ClassMethods
  def define_hook(hook_type, prepend = T.unsafe(nil)); end
end

class VCR::Hooks::FilteredHook < ::Struct
  include ::VCR::VariableArgsBlockCaller

  def conditionally_invoke(*args); end
  def filters; end
  def filters=(_); end
  def hook; end
  def hook=(_); end

  class << self
    def [](*_arg0); end
    def inspect; end
    def keyword_init?; end
    def members; end
    def new(*_arg0); end
  end
end

module VCR::InternetConnection
  extend ::VCR::InternetConnection

  def available?; end
end

VCR::InternetConnection::EXAMPLE_HOST = T.let(T.unsafe(nil), String)

class VCR::LibraryHooks
  def disabled?(hook); end
  def exclusive_hook; end
  def exclusive_hook=(_arg0); end
  def exclusively_enabled(hook); end
end

class VCR::LinkedCassette < ::SimpleDelegator
  def eject(*args); end
  def linked?; end

  class << self
    def list(cassettes, linked_cassettes); end
  end
end

class VCR::LinkedCassette::CassetteList
  include ::Enumerable

  def initialize(cassettes, linked_cassettes); end

  def each; end
  def last; end
  def size; end

  protected

  def wrap(cassette); end
end

class VCR::Logger
  def initialize(stream); end

  def log(message, log_prefix, indentation_level = T.unsafe(nil)); end
  def request_summary(request, request_matchers); end
  def response_summary(response); end
end

module VCR::Logger::Mixin
  def log(message, indentation_level = T.unsafe(nil)); end
  def request_summary(*args); end
  def response_summary(*args); end
end

module VCR::Logger::Null
  private

  def log(*_arg0); end
  def request_summary(*_arg0); end
  def response_summary(*_arg0); end

  class << self
    def log(*_arg0); end
    def request_summary(*_arg0); end
    def response_summary(*_arg0); end
  end
end

VCR::MainThread = T.let(T.unsafe(nil), Thread)
module VCR::Middleware; end

class VCR::Middleware::CassetteArguments
  def initialize; end

  def name(name = T.unsafe(nil)); end
  def options(options = T.unsafe(nil)); end
end

class VCR::Middleware::Rack
  include ::VCR::VariableArgsBlockCaller

  def initialize(app, &block); end

  def call(env); end

  private

  def cassette_arguments(env); end
end

module VCR::Normalizers; end

module VCR::Normalizers::Body
  mixes_in_class_methods ::VCR::Normalizers::Body::ClassMethods

  def initialize(*args); end

  private

  def base_body_hash(body); end
  def serializable_body; end

  class << self
    def included(klass); end
  end
end

module VCR::Normalizers::Body::ClassMethods
  def body_from(hash_or_string); end
  def force_encode_string(string, encoding); end
  def try_encode_string(string, encoding); end
end

module VCR::Normalizers::Header
  def initialize(*args); end

  private

  def convert_to_raw_strings(array); end
  def delete_header(key); end
  def edit_header(key, value = T.unsafe(nil)); end
  def get_header(key); end
  def header_key(key); end
  def normalize_headers; end
end

module VCR::Ping
  private

  def pingecho(host, timeout = T.unsafe(nil), service = T.unsafe(nil)); end

  class << self
    def pingecho(host, timeout = T.unsafe(nil), service = T.unsafe(nil)); end
  end
end

module VCR::RSpec; end

module VCR::RSpec::Metadata
  extend ::VCR::RSpec::Metadata

  def configure!; end
end

class VCR::Request < ::Struct
  include ::VCR::Normalizers::Header
  include ::VCR::Normalizers::Body
  extend ::VCR::Normalizers::Body::ClassMethods

  def initialize(*args); end

  def method(*args); end
  def parsed_uri; end
  def to_hash; end

  private

  def without_standard_port(uri); end

  class << self
    def from_hash(hash); end
  end
end

class VCR::Request::FiberAware
  def proceed; end
  def to_proc; end
end

class VCR::Request::Typed
  def initialize(request, type); end

  def externally_stubbed?; end
  def ignored?; end
  def real?; end
  def recordable?; end
  def stubbed?; end
  def stubbed_by_vcr?; end
  def type; end
  def unhandled?; end
end

class VCR::RequestIgnorer
  include ::VCR::VariableArgsBlockCaller
  include ::VCR::Hooks
  include ::VCR::RequestIgnorer::DefinedHooks
  extend ::VCR::Hooks::ClassMethods

  def initialize; end

  def ignore?(request); end
  def ignore_hosts(*hosts); end
  def ignore_localhost=(value); end
  def unignore_hosts(*hosts); end

  private

  def ignored_hosts; end
end

module VCR::RequestIgnorer::DefinedHooks
  def ignore_request(*filters, &hook); end
end

VCR::RequestIgnorer::LOCALHOST_ALIASES = T.let(T.unsafe(nil), Array)

class VCR::RequestMatcherRegistry
  def initialize; end

  def [](matcher); end
  def register(name, &block); end
  def uri_without_param(*ignores); end
  def uri_without_params(*ignores); end

  private

  def raise_unregistered_matcher_error(name); end
  def register_built_ins; end
  def try_to_register_body_as_json; end
  def uri_without_param_matchers; end
end

VCR::RequestMatcherRegistry::DEFAULT_MATCHERS = T.let(T.unsafe(nil), Array)

class VCR::RequestMatcherRegistry::Matcher < ::Struct
  def matches?(request_1, request_2); end
end

class VCR::RequestMatcherRegistry::URIWithoutParamsMatcher < ::Struct
  def call(request_1, request_2); end
  def partial_uri_from(request); end
  def to_proc; end
end

class VCR::Response < ::Struct
  include ::VCR::Normalizers::Header
  include ::VCR::Normalizers::Body
  extend ::VCR::Normalizers::Body::ClassMethods

  def initialize(*args); end

  def compressed?; end
  def content_encoding; end
  def decompress; end
  def recompress; end
  def to_hash; end
  def update_content_length_header; end
  def vcr_decompressed?; end

  class << self
    def decompress(body, type); end
    def from_hash(hash); end
  end
end

VCR::Response::HAVE_ZLIB = T.let(T.unsafe(nil), TrueClass)

class VCR::ResponseStatus < ::Struct
  def to_hash; end

  class << self
    def from_hash(hash); end
  end
end

module VCR::VariableArgsBlockCaller
  def call_block(block, *args); end
end