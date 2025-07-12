export def sk-bib [
    bib?: string # the bib file to search
    --fields (-f): list<string>
] : [
string -> table
nothing -> table
] {
    
    let cols = match $fields {
        null => [id, title, keyword],
        $f => ([[id, title,keyword], $f] |flatten)
    }
    clear -k
    match $bib {
        null => {'*.bib' | glob $in |$in.0|path basename},
        _ => $bib
    }
    | pandoc $in -st markdown
    | from yaml
    | $in.0.references
    | (
    sk --format {select ...$cols} --preview {table -e}
    --reverse --height 80%
    --preview-window down:67%
    --bind {shift-left: preview-left, shift-right: preview-right}
    )
}

export def bib-to-yaml-table [] : string -> table {
    $in
    |pandoc -f biblatex -st markdown
    |from yaml
    |$in.0.references
    |rename -c {keyword:keywords}
}

export def export-to-bib [
] : list<any> -> string {
    $in | rename -c {keyword:keywords}
    |{references: $in}
    |to yaml
    |[---, $in, ---]
    |str join "\n"
    |pandoc -f markdown -t biblatex
}

def sanitize [
    str: string
] : string -> string {
    $str | str replace --regex -a '[ ‐:-]' '_' 
}

export def --env rename-pdf [
    --dryrun (-n) # Preview without executing mv
] : list<path> -> table {
    let to_rename = $in
    |par-each {|pdf_file| 
    let meta = exiftool -j $pdf_file | from json
    let author_query = $meta | get -i Author 
    let author_last = match ($author_query|compact -e | describe) {
        "list<string>" => ( $author_query | split words | $in.0.1)
        "list<any> (stream)" => null
        "list<nothing>" => null
    } 
    let year = $meta.CreateDate | str substring 0..3 | $in.0
    let filename = [$author_last, $year, (sanitize $meta.Title.0)]|compact | str join "_"
    let name = $"($filename).pdf"
    {from:($pdf_file |path basename), to: $name}
    } 
    if not $dryrun {
        $to_rename | each {|item| if not ($item.from == $item.to) {mv $item.from $item.to} else {print $"($item.from) to ($item.to) is skipped";}}
    } 
    $to_rename
}

export def fm [
    pdf_path: path
    --type (-t)="Article": string
    --keywords (-k): list<string>
    --with_dft (-D)
    --output (-o): string
] : path -> string {
    let meta = $pdf_path | path basename | parse "{stem}.{ext}" |update ext md |$in.0
    let title = $meta.stem
    let note_name = [$meta.stem, $meta.ext] | str join "."
    let frontmatter = {title: $title, type:$type, keywords:$keywords, with_DFT:$with_dft}
    $frontmatter | to yaml | [---, $in, ---] | str join "\n"
    | if ($output != null) {$in | save $output} else {$in}
}

export def --env new-note-path [
    pdf_path: path
] : path -> string {
    let meta = $pdf_path | path basename | parse "{stem}.{ext}" |update ext md |$in.0
    let note_name = [$meta.stem, $meta.ext] | str join "."
    $"($env.NOTES_DIR)/($note_name)"
}

export def --env sk-papers [
    papers_dir?:path
] {
    let papers_dir = match $papers_dir {
    null => $env.PAPERS_DIR,
    $x => $x,
    }
    let select = glob $"($papers_dir)/*.pdf" | sk --preview {exiftool -j $in|from json |transpose field value|table -e} --preview-window down:80% --reverse --height 80%
    clear -k
    exiftool -j $select |from json
}

export def get-note-keywords [
    pdf_path: path
] {
    rg -NUIo --trim --pcre2 '(?<=keywords:)(\n.*)+(?=with)' $pdf_path | lines |each {str replace -a '-' ''| str trim} |str join "," | {($pdf_path|path basename):$in}
}

