
function get_recessions(
    start_sample::String,
    end_sample::String;
    series        = "EURORECM",
    print_csv     = false,
    download_fred = true
    )

# ------------------------------------------------------------------------------
# Creates a Recessions.csv file in the current directory.
# Data are downloaded from FRED using an API
#
# Sometimes a timeout error occurs, so it better to try to have the csv file
# downloaded into the folder.
#
# Author: Lapo Bini, lbini@ucsd.edu
# ------------------------------------------------------------------------------

    data = [];
    if download_fred
        api_key   = "66c080f0ed7880e7df1230ef212fb8c1"
        f         = Fred(api_key)
        recession = get_data(f, series, frequency = "m" )
        data      = recession.data;
        start     = findall(isnan.(recession.data.value[1:end-1]))

        # end-1 above takes care of the NaN at the end of the Period 
        if isempty(start)
            data = data[:,end-1:end] |> Array{Any,2};
        else
            data = data[start[end]+1:end, end-1:end]|> Array{Any,2};
        end

        if print_csv == true
            CSV.write("./"*series*".csv",  DataFrame(data, :auto))
        end
    else
        data =  DataFrame(XLSX.readtable(data_file, "Recessions", header = false)) |> Array{Any,2};
    end

    sample_bool = (data[:,1] .>= DateTime(start_sample, "dd/mm/yyyy");) .&
                  (data[:,1] .<= DateTime(end_sample, "dd/mm/yyyy"););
    data_tmp    = data[sample_bool,:];
    tmp         = findall(data_tmp[:,2].==1);
    data_tmp    = data_tmp[tmp,:];

    data_tmp[:,1] = lastdayofmonth.(data_tmp[:,1]);
    start_end     = Array{Float64,2}(undef, size(data_tmp,1), size(data_tmp,2)).*NaN;

    # Create intervals of time for the crisis
    start_end[1,1] = 1;
    for i in 1:size(data_tmp,1)-1
        idx = lastdayofmonth(data_tmp[i,1] + Month(1))
        if idx != data_tmp[i+1,1]

            srt = findall(isnan.(start_end[:,1]))[1];
            fin = findall(isnan.(start_end[:,2]))[1];

            start_end[srt,1] = i+1;
            start_end[fin,2] = i;
        end
    end

    fin              = findall(isnan.(start_end[:,2]))[1];
    start_end[fin,2] = size(data_tmp,1);
    rem              = findall(isnan.(start_end[:,2]))[1];
    idx_date         = start_end[1:rem-1,:] |> Array{Int64,2};

    # Combine to obtain tuples of interval
    rec  = [(data_tmp[idx_date[i,1],1], data_tmp[idx_date[i,2],1]) for i in 1:size(idx_date,1)];

    return rec

end
