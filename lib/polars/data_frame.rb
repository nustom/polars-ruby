module Polars
  class DataFrame
    attr_accessor :_df

    def initialize(data = nil)
      if defined?(ActiveRecord) && (data.is_a?(ActiveRecord::Relation) || data.is_a?(ActiveRecord::Result))
        result = data.is_a?(ActiveRecord::Result) ? data : data.connection.select_all(data.to_sql)
        data = {}
        result.columns.each_with_index do |k, i|
          data[k] = result.rows.map { |r| r[i] }
        end
      end

      if data.nil?
        self._df = hash_to_rbdf({})
      elsif data.is_a?(Hash)
        data = data.transform_keys { |v| v.is_a?(Symbol) ? v.to_s : v }
        self._df = hash_to_rbdf(data)
      elsif data.is_a?(Array)
        self._df = sequence_to_rbdf(data)
      elsif data.is_a?(Series)
        self._df = series_to_rbdf(data)
      else
        raise ArgumentError, "DataFrame constructor called with unsupported type; got #{data.class.name}"
      end
    end

    def self._from_rbdf(rb_df)
      df = DataFrame.allocate
      df._df = rb_df
      df
    end

    def self._read_csv(
      file,
      has_header: true,
      columns: nil,
      sep: str = ",",
      comment_char: nil,
      quote_char: '"',
      skip_rows: 0,
      dtypes: nil,
      null_values: nil,
      ignore_errors: false,
      parse_dates: false,
      n_threads: nil,
      infer_schema_length: 100,
      batch_size: 8192,
      n_rows: nil,
      encoding: "utf8",
      low_memory: false,
      rechunk: true,
      skip_rows_after_header: 0,
      row_count_name: nil,
      row_count_offset: 0,
      sample_size: 1024,
      eol_char: "\n"
    )
      if file.is_a?(String) || (defined?(Pathname) && file.is_a?(Pathname))
        path = Utils.format_path(file)
      else
        path = nil
        # if isinstance(file, BytesIO):
        #     file = file.getvalue()
        # if isinstance(file, StringIO):
        #     file = file.getvalue().encode()
      end

      dtype_list = nil
      dtype_slice = nil
      # if dtypes is not None:
      #     if isinstance(dtypes, dict):
      #         dtype_list = []
      #         for k, v in dtypes.items():
      #             dtype_list.append((k, py_type_to_dtype(v)))
      #     elif isinstance(dtypes, Sequence):
      #         dtype_slice = dtypes
      #     else:
      #         raise ValueError("dtype arg should be list or dict")

      processed_null_values = Utils._process_null_values(null_values)

      # if isinstance(columns, str):
      #     columns = [columns]
      # if isinstance(file, str) and "*" in file:
      #     dtypes_dict = None
      #     if dtype_list is not None:
      #         dtypes_dict = {name: dt for (name, dt) in dtype_list}
      #     if dtype_slice is not None:
      #         raise ValueError(
      #             "cannot use glob patterns and unnamed dtypes as `dtypes` argument;"
      #             " Use dtypes: Mapping[str, Type[DataType]"
      #         )
      #     from polars import scan_csv

      #     scan = scan_csv(
      #         file,
      #         has_header=has_header,
      #         sep=sep,
      #         comment_char=comment_char,
      #         quote_char=quote_char,
      #         skip_rows=skip_rows,
      #         dtypes=dtypes_dict,
      #         null_values=null_values,
      #         ignore_errors=ignore_errors,
      #         infer_schema_length=infer_schema_length,
      #         n_rows=n_rows,
      #         low_memory=low_memory,
      #         rechunk=rechunk,
      #         skip_rows_after_header=skip_rows_after_header,
      #         row_count_name=row_count_name,
      #         row_count_offset=row_count_offset,
      #         eol_char=eol_char,
      #     )
      #     if columns is None:
      #         return self._from_pydf(scan.collect()._df)
      #     elif is_str_sequence(columns, allow_str=False):
      #         return self._from_pydf(scan.select(columns).collect()._df)
      #     else:
      #         raise ValueError(
      #             "cannot use glob patterns and integer based projection as `columns`"
      #             " argument; Use columns: List[str]"
      #         )

      projection, columns = Utils.handle_projection_columns(columns)

      _from_rbdf(
        RbDataFrame.read_csv(
          file,
          infer_schema_length,
          batch_size,
          has_header,
          ignore_errors,
          n_rows,
          skip_rows,
          projection,
          sep,
          rechunk,
          columns,
          encoding,
          n_threads,
          path,
          dtype_list,
          dtype_slice,
          low_memory,
          comment_char,
          quote_char,
          processed_null_values,
          parse_dates,
          skip_rows_after_header,
          Utils._prepare_row_count_args(row_count_name, row_count_offset),
          sample_size,
          eol_char
        )
      )
    end

    def self._read_parquet(file)
      if file.is_a?(String) || (defined?(Pathname) && file.is_a?(Pathname))
        file = Utils.format_path(file)
      end

      _from_rbdf(RbDataFrame.read_parquet(file))
    end

    def self._read_json(file)
      if file.is_a?(String) || (defined?(Pathname) && file.is_a?(Pathname))
        file = Utils.format_path(file)
      end

      _from_rbdf(RbDataFrame.read_json(file))
    end

    def self._read_ndjson(file)
      if file.is_a?(String) || (defined?(Pathname) && file.is_a?(Pathname))
        file = Utils.format_path(file)
      end

      _from_rbdf(RbDataFrame.read_ndjson(file))
    end

    def shape
      _df.shape
    end

    def height
      _df.height
    end

    def width
      _df.width
    end

    def columns
      _df.columns
    end

    def columns=(columns)
      _df.set_column_names(columns)
    end

    def dtypes
      _df.dtypes.map(&:to_sym)
    end

    def schema
      columns.zip(dtypes).to_h
    end

    # def ==(other)
    # end

    # def !=(other)
    # end

    # def >(other)
    # end

    # def <(other)
    # end

    # def >=(other)
    # end

    # def <=(other)
    # end

    # def *(other)
    # end

    # def /(other)
    # end

    # def +(other)
    # end

    # def -(other)
    # end

    # def %(other)
    # end

    def to_s
      _df.to_s
    end
    alias_method :inspect, :to_s

    def include?(name)
      columns.include?(name)
    end

    def [](name)
      Utils.wrap_s(_df.column(name))
    end

    # def []=(key, value)
    # end

    def to_h(as_series: true)
      if as_series
        get_columns.to_h { |s| [s.name, s] }
      else
        get_columns.to_h { |s| [s.name, s.to_a] }
      end
    end

    # def to_hs / to_a
    # end

    # def to_numo
    # end

    # no to_pandas

    def to_series(index = 0)
      if index < 0
        index = columns.length + index
      end
      Utils.wrap_s(_df.select_at_idx(index))
    end

    def write_json(
      file,
      pretty: false,
      row_oriented: false
    )
      if file.is_a?(String) || (defined?(Pathname) && file.is_a?(Pathname))
        file = Utils.format_path(file)
      end

      _df.write_json(file, pretty, row_oriented)
      nil
    end

    def write_ndjson(file)
      if file.is_a?(String) || (defined?(Pathname) && file.is_a?(Pathname))
        file = Utils.format_path(file)
      end

      _df.write_ndjson(file)
      nil
    end

    def write_csv(
      file = nil,
      has_header: true,
      sep: ",",
      quote: '"',
      batch_size: 1024,
      datetime_format: nil,
      date_format: nil,
      time_format: nil,
      float_precision: nil,
      null_value: nil
    )
      if sep.length > 1
        raise ArgumentError, "only single byte separator is allowed"
      elsif quote.length > 1
        raise ArgumentError, "only single byte quote char is allowed"
      elsif null_value == ""
        null_value = nil
      end

      if file.nil?
        buffer = StringIO.new
        buffer.set_encoding(Encoding::BINARY)
        _df.write_csv(
          buffer,
          has_header,
          sep.ord,
          quote.ord,
          batch_size,
          datetime_format,
          date_format,
          time_format,
          float_precision,
          null_value
        )
        buffer.rewind
        return buffer.read.force_encoding(Encoding::UTF_8)
      end

      if file.is_a?(String) || (defined?(Pathname) && file.is_a?(Pathname))
        file = Utils.format_path(file)
      end

      _df.write_csv(
        file,
        has_header,
        sep.ord,
        quote.ord,
        batch_size,
        datetime_format,
        date_format,
        time_format,
        float_precision,
        null_value,
      )
      nil
    end

    # def write_avro
    # end

    # def write_ipc
    # end

    def write_parquet(
      file,
      compression: "zstd",
      compression_level: nil,
      statistics: false,
      row_group_size: nil
    )
      if compression.nil?
        compression = "uncompressed"
      end
      if file.is_a?(String) || (defined?(Pathname) && file.is_a?(Pathname))
        file = Utils.format_path(file)
      end

      _df.write_parquet(
        file, compression, compression_level, statistics, row_group_size
      )
    end

    def estimated_size(unit = "b")
      sz = _df.estimated_size
      Utils.scale_bytes(sz, to: unit)
    end

    # def transpose
    # end

    def reverse
      select(Polars.col("*").reverse)
    end

    def rename(mapping)
      lazy.rename(mapping).collect(no_optimization: true)
    end

    def insert_at_idx(index, series)
      if index < 0
        index = columns.length + index
      end
      _df.insert_at_idx(index, series._s)
      self
    end

    def filter(predicate)
      lazy.filter(predicate).collect
    end

    # def describe
    # end

    # def find_idx_by_name
    # end

    # def replace_at_idx
    # end

    def sort(by, reverse: false, nulls_last: false)
      _from_rbdf(_df.sort(by, reverse, nulls_last))
    end

    def frame_equal(other, null_equal: true)
      _df.frame_equal(other._df, null_equal)
    end

    # def replace
    # end

    def slice(offset, length = nil)
      if !length.nil? && length < 0
        length = height - offset + length
      end
      _from_rbdf(_df.slice(offset, length))
    end

    def limit(n = 5)
      head(n)
    end

    def head(n = 5)
      _from_rbdf(_df.head(n))
    end

    def tail(n = 5)
      _from_rbdf(_df.tail(n))
    end

    # def drop_nulls
    # end

    # def pipe
    # end

    # def with_row_count
    # end

    def groupby(by, maintain_order: false)
      lazy.groupby(by, maintain_order: maintain_order)
    end

    # def groupby_rolling
    # end

    # def groupby_dynamic
    # end

    # def upsample
    # end

    # def join_asof
    # end

    def join(other, left_on: nil, right_on: nil, on: nil, how: "inner", suffix: "_right")
      lazy
        .join(
          other.lazy,
          left_on: left_on,
          right_on: right_on,
          on: on,
          how: how,
          suffix: suffix,
        )
        .collect(no_optimization: true)
    end

    # def apply
    # end

    def with_column(column)
      lazy
        .with_column(column)
        .collect(no_optimization: true, string_cache: false)
    end

    # def hstack
    # end

    # def vstack
    # end

    # def extend
    # end

    # def drop
    # end

    # def drop_in_place
    # end

    # def cleared
    # end

    # clone handled by initialize_copy

    def get_columns
      _df.get_columns.map { |s| Utils.wrap_s(s) }
    end

    def get_column(name)
      self[name]
    end

    # def fill_null
    # end

    def fill_nan(fill_value)
      lazy.fill_nan(fill_value).collect(no_optimization: true)
    end

    # def explode
    # end

    # def pivot
    # end

    # def melt
    # end

    # def unstack
    # end

    # def partition_by
    # end

    # def shift
    # end

    # def shift_and_fill
    # end

    def is_duplicated
      Utils.wrap_s(_df.is_duplicated)
    end

    def is_unique
      Utils.wrap_s(_df.is_unique)
    end

    def lazy
      wrap_ldf(_df.lazy)
    end

    def select(exprs)
      _from_rbdf(
        lazy
          .select(exprs)
          .collect(no_optimization: true, string_cache: false)
          ._df
      )
    end

    def with_columns(exprs)
      if !exprs.nil? && !exprs.is_a?(Array)
        exprs = [exprs]
      end
      lazy
        .with_columns(exprs)
        .collect(no_optimization: true, string_cache: false)
    end

    def n_chunks(strategy: "first")
      if strategy == "first"
        _df.n_chunks
      elsif strategy == "all"
        get_columns.map(&:n_chunks)
      else
        raise ArgumentError, "Strategy: '{strategy}' not understood. Choose one of {{'first',  'all'}}"
      end
    end

    def max(axis: 0)
      if axis == 0
        _from_rbdf(_df.max)
      elsif axis == 1
        Utils.wrap_s(_df.hmax)
      else
        raise ArgumentError, "Axis should be 0 or 1."
      end
    end

    def min(axis: 0)
      if axis == 0
        _from_rbdf(_df.min)
      elsif axis == 1
        Utils.wrap_s(_df.hmin)
      else
        raise ArgumentError, "Axis should be 0 or 1."
      end
    end

    def sum(axis: 0, null_strategy: "ignore")
      case axis
      when 0
        _from_rbdf(_df.sum)
      when 1
        Utils.wrap_s(_df.hsum(null_strategy))
      else
        raise ArgumentError, "Axis should be 0 or 1."
      end
    end

    def mean(axis: 0, null_strategy: "ignore")
      case axis
      when 0
        _from_rbdf(_df.mean)
      when 1
        Utils.wrap_s(_df.hmean(null_strategy))
      else
        raise ArgumentError, "Axis should be 0 or 1."
      end
    end

    def std(ddof: 1)
      _from_rbdf(_df.std(ddof))
    end

    def var(ddof: 1)
      _from_rbdf(_df.var(ddof))
    end

    def median
      _from_rbdf(_df.median)
    end

    # def product
    # end

    # def quantile(quantile, interpolation: "nearest")
    # end

    # def to_dummies
    # end

    # def unique
    # end

    # def n_unique
    # end

    def rechunk
      _from_rbdf(_df.rechunk)
    end

    def null_count
      _from_rbdf(_df.null_count)
    end

    # def sample
    # end

    # def fold
    # end

    # def row
    # end

    # def rows
    # end

    # def shrink_to_fit
    # end

    # def take_every
    # end

    # def hash_rows
    # end

    # def interpolate
    # end

    def is_empty
      height == 0
    end
    alias_method :empty?, :is_empty

    # def to_struct(name)
    # end

    # def unnest
    # end

    private

    def initialize_copy(other)
      super
      self._df = _df._clone
    end

    def hash_to_rbdf(data)
      RbDataFrame.read_hash(data)
    end

    def sequence_to_rbdf(data)
      RbDataFrame.new(data.map(&:_s))
    end

    def series_to_rbdf(data)
      RbDataFrame.new([data._s])
    end

    def wrap_ldf(ldf)
      LazyFrame._from_rbldf(ldf)
    end

    def _from_rbdf(rb_df)
      self.class._from_rbdf(rb_df)
    end
  end
end
