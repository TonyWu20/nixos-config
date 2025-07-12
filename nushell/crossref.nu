# A script to call crossref api for literature search

const user_agent = ["User-Agent", "TonyWu-crossref-nushell(mailto:tony.w21@gmail.com)"]
const api_prefix = "https://api.crossref.org/works"
const accept_xml = ["Accept", 'application/vnd.crossref.unixsd+xml']

# Get metadata by doi
export def get-work-by-doi [
    doi:string # the doi of the work
]: string -> table {
    $doi 
    | url encode --all
    | [$api_prefix, $in] 
    | str join "/"
    | http get -H $user_agent $in
    | get message
}

export def query-works [
    queries: string # 
    --bibliographic (-b)
    --rows (-R):int
    --keywords (-k): list<string>
] {
    let filters = [[DOI,title, short-container-title], $keywords] | flatten |str join ","
    let rows = if $rows != null {$rows} else {2}
    [$api_prefix, "?query.bibliographic=", $'"($queries)"', $"&rows=($rows)", $'&select=($filters)']
    | str join
    | http get -H $user_agent $in
    | get message
    | get items
    | update cells -c ["title", "short-container-title"] {|list| $list.0}
}

export def fetch-meta [
    DOI: string # doi
]: string -> any {
    $DOI
    | url encode
    | ["http://dx.doi.org", $in]
    | str join "/"
    | http get -H ([$user_agent, $accept_xml]|flatten) $in
}

export def decide-append-chars [
    found_len : int
] : int -> string {
    if $found_len > 0 {
    let found_len = $found_len - 1
    let chars = seq char a z 
    const size = 26
    let lengths = $found_len // $size 
    let choice = $found_len mod $size
    let widths = seq 0 $lengths | length
    seq 0 $lengths| each {|i| if ($i < ($widths - 1)) {'z'} else {$chars |get $choice}} |str join ""
    } else {
        ''
    }
}

def check-id [
    bibfile: path # path to biblatex file `.bib`
    new_id: string # id of new citation to be inserted
]  {
    open $bibfile
    | bib-to-yaml-table
    | select id 
    | where id =~ $new_id 
    | length 
    | if $in > 0 {[$new_id, (decide-append-chars $in)] |str join} else {$new_id}
}

export def fetch-bib [
    DOI: string # DOI
    --keyword (-k): list<string> # keywords to add
    --save (-s): string # bib file to save/append to
] : [
    string -> string 
    nothing -> string
] {
    let bib = $DOI
    | if ($in|str starts-with 'https://doi.org/') {url encode} else {url encode | ["https://doi.org", $in] | str join "/"}
    |http get -H ["User-Agent", "TonyWu-crossref-nushell(mailto:tony.w21@gmail.com)", "Accept", "application/x-bibtex"] $in
    | if $keyword != null {
        let keywords = $keyword | str join ","
        $in |str replace -rm '\s+}$' $', keywords={($keywords)} }'
    } else {$in};

    if $save != null {
        let in_yaml = $bib | bib-to-yaml-table |$in.0
        let checked_id = check-id $save $in_yaml.id
        let checked_bib = if ($checked_id != $in_yaml.id) {
            $in_yaml |update id $checked_id |[$in] |export-to-bib
        } else {
            $bib
        }
        print $checked_bib
        $checked_bib|save --append $save
    } else {$bib}
}

export def cityu-doi [
    DOI?: string # DOI
]: string -> string {
    if ($DOI == null) { $in } else $DOI
    |if ($in | str starts-with "https://doi.org/") {str replace "doi.org" "doi-org.ezproxy.cityu.edu.hk"} else {["https://doi-org.ezproxy.cityu.edu.hk", $in]|str join "/"}
}

