module WillPaginate
  # == Global options for helpers
  #
  # Options for pagination helpers are optional and get their default values from the
  # WillPaginate::ViewHelpers.pagination_options hash. You can write to this hash to
  # override default options on the global level:
  #
  # WillPaginate::ViewHelpers.pagination_options[:prev_label] = 'Previous page'
  module ViewHelpers
  # default options that can be overridden on the global level
  @@pagination_options = {
    :class => 'pagination',
    :prev_label => '&lt;&lt;',
    :next_label => '&gt;&gt;',
    :inner_window => 4, # links around the current page
    :outer_window => 1, # links around beginning and end
    :separator => ' ', # single space is friendly to spiders and non-graphic browsers
    :param_name => :page,
    :params => nil,
    :renderer => 'WillPaginate::LinkRenderer',
    :page_links => true,
    :container => true
  }
  end
end