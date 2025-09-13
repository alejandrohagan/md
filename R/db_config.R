#' `db_config` Dataset
#'
#' A configuration list used to set various parameters for connecting and interacting
#' with the database system (likely DuckDB based on the naming conventions). These parameters
#' allow users to customize database connection, performance settings, file handling, logging,
#' and security features. The dataset contains a series of named configuration options with string
#' values, including some Boolean-like options.
#'
#' @format A list of named character strings, where each entry is a configuration option for the database.
#' The list includes various settings like memory allocation, logging preferences, HTTP settings, and more.
#' @docType data
#' @name db_config
#' @usage data(db_config)
#' @keywords datasets
#' @examples
#' data(db_config)
#' # Access specific configuration value
#' db_config$access_mode
#' db_config$max_memory
#'
#' @section Configuration Parameters:
#' - **access_mode** (`character`): Defines the access mode for the database. Example: `"automatic"`.
#' - **allocator_background_threads** (`character`): Whether background threads are used for memory allocation. Example: `"false"`.
#' - **allocator_bulk_deallocation_flush_threshold** (`character`): Threshold for bulk deallocation flushing. Example: `"512MB"`.
#' - **allocator_flush_threshold** (`character`): Threshold for memory flushing. Example: `"128MB"`.
#' - **allow_community_extensions** (`character`): Whether community extensions are allowed. Example: `"true"`.
#' - **allow_extensions_metadata_mismatch** (`character`): Whether metadata mismatch for extensions is allowed. Example: `"false"`.
#' - **allow_persistent_secrets** (`character`): Whether persistent secrets are allowed. Example: `"true"`.
#' - **allow_unredacted_secrets** (`character`): Whether unredacted secrets are allowed. Example: `"false"`.
#' - **allow_unsigned_extensions** (`character`): Whether unsigned extensions are allowed. Example: `"false"`.
#' - **allowed_directories** (`character`): List of allowed directories. Default: `"[]"`.
#' - **allowed_paths** (`character`): List of allowed paths. Default: `"[]"`.
#' - **arrow_large_buffer_size** (`character`): Whether large buffers are used for Arrow format. Example: `"false"`.
#' - **arrow_lossless_conversion** (`character`): Whether Arrow data uses lossless conversion. Example: `"false"`.
#' - **arrow_output_list_view** (`character`): Whether Arrow data is output in a list view. Example: `"false"`.
#' - **autoinstall_extension_repository** (`character`): URL for the auto-install extension repository.
#' - **autoinstall_known_extensions** (`character`): Whether to auto-install known extensions. Example: `"false"`.
#' - **autoload_known_extensions** (`character`): Whether to auto-load known extensions. Example: `"false"`.
#' - **binary_as_string** (`character`): Whether binary data is treated as strings. Example: `"false"`.
#' - **ca_cert_file** (`character`): Path to the certificate authority file for SSL connections.
#' - **catalog_error_max_schemas** (`character`): Maximum number of schemas before an error is thrown. Example: `"100"`.
#' - **checkpoint_threshold** (`character`): Threshold size for checkpointing. Example: `"16MB"`.
#' - **wal_autocheckpoint** (`character`): WAL (Write-Ahead Log) auto-checkpoint size. Example: `"16MB"`.
#' - **custom_extension_repository** (`character`): Custom repository URL for extensions.
#' - **custom_user_agent** (`character`): Custom user-agent string for HTTP requests.
#' - **default_block_size** (`character`): Default block size for processing. Example: `"262144"`.
#' - **default_collation** (`character`): Default collation for sorting. Example: `""` (empty).
#' - **default_null_order** (`character`): Default order for null values. Example: `"NULLS_LAST"`.
#' - **default_order** (`character`): Default sorting order. Example: `"ASC"`.
#' - **default_secret_storage** (`character`): Default storage location for secrets. Example: `"local_file"`.
#' - **disable_parquet_prefetching** (`character`): Whether to disable Parquet prefetching. Example: `"false"`.
#' - **disabled_compression_methods** (`character`): List of disabled compression methods.
#' - **disabled_filesystems** (`character`): List of disabled filesystems.
#' - **disabled_log_types** (`character`): List of disabled log types.
#' - **duckdb_api** (`character`): API to use for DuckDB. Example: `"cli"`.
#' - **enable_external_access** (`character`): Whether external access is enabled. Example: `"true"`.
#' - **enable_external_file_cache** (`character`): Whether external file caching is enabled. Example: `"true"`.
#' - **enable_fsst_vectors** (`character`): Whether FSST vectors are enabled. Example: `"false"`.
#' - **enable_geoparquet_conversion** (`character`): Whether GeoParquet conversion is enabled. Example: `"true"`.
#' - **enable_http_metadata_cache** (`character`): Whether HTTP metadata caching is enabled. Example: `"false"`.
#' - **enable_logging** (`character`): Whether logging is enabled. Example: `"false"`.
#' - **enable_macro_dependencies** (`character`): Whether macro dependencies are enabled. Example: `"false"`.
#' - **enable_object_cache** (`character`): Whether object caching is enabled. Example: `"false"`.
#' - **enable_server_cert_verification** (`character`): Whether server certificate verification is enabled. Example: `"false"`.
#' - **enable_view_dependencies** (`character`): Whether view dependencies are enabled. Example: `"false"`.
#' - **enabled_log_types** (`character`): List of enabled log types.
#' - **extension_directory** (`character`): Directory for extensions.
#' - **external_threads** (`character`): Number of external threads. Example: `"1"`.
#' - **force_download** (`character`): Whether to force download of extensions. Example: `"false"`.
#' - **http_keep_alive** (`character`): Whether HTTP keep-alive is enabled. Example: `"true"`.
#' - **http_proxy** (`character`): HTTP proxy server URL.
#' - **http_proxy_password** (`character`): Password for the HTTP proxy.
#' - **http_proxy_username** (`character`): Username for the HTTP proxy.
#' - **http_retries** (`character`): Number of HTTP retries. Example: `"3"`.
#' - **http_retry_backoff** (`character`): Backoff time between retries. Example: `"4"`.
#' - **http_retry_wait_ms** (`character`): Retry wait time in milliseconds. Example: `"100"`.
#' - **http_timeout** (`character`): HTTP request timeout in seconds. Example: `"30"`.
#' - **immediate_transaction_mode** (`character`): Whether immediate transaction mode is enabled. Example: `"false"`.
#' - **index_scan_max_count** (`character`): Maximum number of index scan results. Example: `"2048"`.
#' - **index_scan_percentage** (`character`): Index scan percentage. Example: `"0.001"`.
#' - **lock_configuration** (`character`): Whether to lock configuration. Example: `"false"`.
#' - **logging_level** (`character`): Logging level. Example: `"INFO"`.
#' - **logging_mode** (`character`): Logging mode. Example: `"LEVEL_ONLY"`.
#' - **logging_storage** (`character`): Storage for logs. Example: `"memory"`.
#' - **max_memory** (`character`): Maximum memory usage as a percentage or fixed value. Example: `"80%"`.
#' - **memory_limit** (`character`): Memory limit as a percentage. Example: `"80%"`.
#' - **max_temp_directory_size** (`character`): Maximum temporary directory size. Example: `"90%"`.
#' - **max_vacuum_tasks** (`character`): Maximum vacuum tasks. Example: `"100"`.
#' - **old_implicit_casting** (`character`): Whether old implicit casting is allowed. Example: `"false"`.
#' - **parquet_metadata_cache** (`character`): Whether Parquet metadata caching is enabled. Example: `"false"`.
#' - **password** (`character`): Password for database access.
#' - **prefetch_all_parquet_files** (`character`): Whether to prefetch all Parquet files. Example: `"false"`.
#' - **preserve_insertion_order** (`character`): Whether to preserve insertion order in datasets. Example: `"true"`.
#' - **produce_arrow_string_view** (`character`): Whether to produce Arrow string view. Example: `"false"`.
#' - **s3_access_key_id** (`character`): AWS S3 access key.
#' - **s3_endpoint** (`character`): S3 endpoint URL.

