generated_path=~/git/personal-site/generated
template_path=~/git/personal-site/template
content_path=~/git/personal-site/content
program_name=$0
first_arg=`tr [A-Z] [a-z] <<< ${1}`

shift 1

while getopts "t:c:v:h:" opt; do
  case ${opt} in
    v) 
      echo "Setting: $OPTARG" >&1
      variables+=$OPTARG
      ;;
    t) 
      echo "Setting: $OPTARG" >&1
      template+=$OPTARG
      ;;
    h) 
      usage
      ;;
    c) 
      echo "Setting: $OPTARG" >&1
      content+=$OPTARG
      ;;
    \?) 
      echo "Ignoring: $OPTARG" >&1
      ;;
    *) 
      echo "Star ignore: $OPTARG" >&1
      ;;
  esac
done

shift $((OPTIND - 1))

usage() { echo "Usage: $program_name [-t template/path/dir/] [-c content/path/dir/] [-h]" 1>&2; exit 1; }
template_formatting_error() { echo "Template Directory layout: $template/header.ini $template/blurb.ini $template/nav.ini $template/nav_element.ini $template/blog.ini" 1>&2; exit 1; }
content_formatting_error() { echo "Content Directory layout: $content/header.txt $content/blurb.txt $content/nav.txt [directory/blogs.txt ...]" 1>&2; exit 1; }
blog_formatting_error() { echo "Blog files must contain either a new line, a data or a header followed by a new line or another data and a new line before text appears" 1>&2; exit 1; }

generate_nav_section() {
  # Break reached generate a nav section
  export nav_header="${nav_content[0]}"
  nav_element=""
  for ((i=1; i<=${#nav_content[@]}; i++))
  do
    export nav_element+="<li id=\"location\">"${nav_content[$i]}"</li>"
  done
  nav_data+=`envsubst < "$template/nav.ini"`
  nav_content=()
}

generate_page() {
if [ -f "${generated_path}/${page}.html" ]; then
  echo "$page.html already exists in $generated_path";
  mv "${generated_path}/${page}.html" "${generated_path}/${page}.html.old";
fi
echo "Creating $generated_path/$page.html...";
cat <<- _EOF_ > $generated_path/$page.html
<html>
  <head>
    <link rel="stylesheet" type="text/css" href="/style.css">
    <title> ${title} </title>
  </head>
  <body>
    <div id = "wrapper" class="noselect">
      ${header_data}
      <div id="side">
        <div id="ratepicker"  unselectable='on' onselectstart='return false;'>
          <div id = "currate"></div>
        </div>
        ${blurb_data}
        ${nav_data}
      </div>
      ${blog_data} 
    </div>

    <!-- shadaah -->
    <script id="vertexShader" type="x-shader/x-vertex">
      precision highp float;

        varying vec2 vUv;
        attribute float displacement;
        varying vec3 vNormal;
        uniform float amp;

        void main() {
            vNormal = normal;
            vUv = uv;
            vec3 newPos = position; // + normal * vec3(displacement * amp);
            gl_Position = projectionMatrix * modelViewMatrix * vec4(newPos, 1.0 );
        }

    </script>
    <script id="juliaSINE-fs" type="x-shader/x-fragment">
      precision highp float;

      uniform float time;
      uniform vec2 resolution;
      varying vec2 vUv;
      varying vec3 vNormal;
      uniform float amp;
      uniform float mousex;
      uniform float mousey;

      float cosh(float val)
      {
        float tmp = exp(val);
        float cosH = (tmp + 1.0 / tmp) / 2.0;
        return cosH;
      }

      float sinh(float val)
      {
        float tmp = exp(val);
        float sinH = (tmp - 1.0 / tmp) / 2.0;
        return sinH;
      }
      void main(void) {
        vec2 position = vUv;
        float x = (position.x - 0.5) * 9.42;
        float y = (position.y - 0.5) * 9.42;

        float hue;
        float saturation;
        float value;
        float hueRound;
        int hueIndex;
        float f;
        float p;
        float q;
        float t;

        int itter = 256;
        //float cx = 1.0;
        //float cy =  1.9;
        //float cx = 1.2;
        //float cy =  0.5;
        float cx = mousex;
        float cy =  mousey;


        float tempX = 0.0;
        float ctempX = 0.0;
        int i = 0;
        int runaway = 0;
        float z = 0.0;
        float zf = 0.0;


        for (int i=0; i < 256; i++) {

          tempX = sin(x) * cosh(y);
          y = cos(x) * sinh(y);
          x = tempX;

          ctempX = x * float(cx) - y * float(cy);
          y = x * float(cy) + y * float(cx);
          x = ctempX;
          z = x*x + y*y;
          if (runaway == 0 && z > 2500.0) {
            runaway = i;
            zf = sqrt(z);
            //break;
          }
        }
        float br = 0.0;
        if (runaway != 0) {
          //NIC COLOURING
          //float z = sqrt(xf*xf + yf*yf);
          br = log2(1.75 + float(runaway) - log2(log2(zf))) / log2(float(itter));

        } else {
          //gl_FragColor = vec4(0.0, 0.0, 0.0, 0.0);
          br = log2(1.75 + float(itter) - log2(log2(z))) / log2(float(itter));
          br = 1.0;

        }
        gl_FragColor = vec4(abs(br - amp), abs(amp*amp - br*0.75), amp*amp, 1.0);
      }

    </script>

    <!-- j whattt? -->
    <script src="js/three.min.js"></script>
    <script id="main" src="js/scripts.js"></script>

  </body>
</html>
_EOF_
}

if [ ! -z "$first_arg" ]; then
  usage
  exit;
fi

# Setup template path
if [ -z "$template" ]; then
  template="${template_path}/default"
  echo "template path unset using default path: $template";
else
  echo "template path set: $template";
fi

if [ ! -d "$template/" ] || [ ! -f "$template/header.ini" ] || [ ! -f "$template/blurb.ini" ] || [ ! -f "$template/nav.ini" ] || [ ! -f "$template/nav_element.ini" ] || [ ! -f "$template/blog.ini" ]; then
  template_formatting_error
  exit;
fi

# Setup content path 
if [ -z "$content" ]; then
  content="${content_path}"
  echo "content path unset using default path: $content";
else
  echo "content path set: $content";
fi

if [ ! -d "$content" ] || [ ! -f "$content/header.txt" ] || [ ! -f "$content/blurb.txt" ] || [ ! -f "$content/nav.txt" ]; then
  content_formatting_error
  exit;
fi

# For each directory
  # Read main header.txt (unless a sub is present in directory)
  # Set env variables (Title, Header, SubHeader)
  # envsubst the template
  # save as header var
  #
  # Read main blurb.txt (unless a sub is present in directory)
  # For each line until new line, append line to blurb_content, wrap in <p>
  # envsubst the template blurb
  # save as nav var blurb
  # 
  # Read main nav.txt (unless a sub is present in directory)
  # First line is set to nav_header
  # For each line until new line, set line to nav_contnet 
  # envsubst the template nav_element, append to nav_element until new line
  # envsubst the template nav
  # save as nav var
  #
  # Read every file other then the blurb/header/nav labeled ones
  # First line takes date variable
  # Second line takes header variable, if new line, header is skipped
  # Every other line from this point on is read until a new line is met, wrap in <p>
  # store into variable blog_text
  # envsubst the template blog
  # save as nav blog
  # 
  # Generate the page according to directory name (no more passing in "page"
  # Move if overlaps
  # move to next directory

echo "Template: [$template]"
echo "Content: [$content]"

for dir in $content/*/
do
  page=${dir%*/}
  page=${page##*/}
  echo Parsing Directory: [$dir] ...
  echo " >>> Header ..."
  #TODO: Need to test if current directory has a header override
  # Avoid pipe to preserve scope, pipes create new env
  header_content=()
  while read line
  do
    if [ ! -z "$line" ]; then
      header_content+=("$line")
    fi
  done < "$content/header.txt"

  export title="${header_content[0]}"
  export header=${header_content[1]}
  export sub_header=${header_content[2]}

  header_data=`envsubst < "$template/header.ini"`
  export header=""
  export sub_header=""

  echo " >>> Blurb..."
  blurb_data=""
  while read line
  do
    if [ ! -z "$line" ]; then
      # Run template against every line in blurb content
      export blurb_content=$line
      blurb_data+=`envsubst < "$template/blurb.ini"`"<br/>"
    fi
  done < "$content/blurb.txt"

  echo " >>> Nav..."
  nav_content=()
  nav_data=""
  should_generate_line=0
  while read line
  do
    # Consume lines until a break
    if [ ! -z "$line" ]; then
      should_generate_line=1
      nav_content+=("$line")
    else
      generate_nav_section
      should_generate_line=0
    fi
  done < "$content/nav.txt"


  if [ $should_generate_line -eq 1 ]; then
    generate_nav_section
  fi
  should_generate_line=0

  echo " >>> Blog..."
  blog_data=""
  #sorted_dir=$(echo ${dir}* | xargs -n1 | sort | xargs)
  sorted_dir=$(echo ${dir}*)
  for file in ${sorted_dir}
  do
    blog_path=${file%*/}
    blog=${blog_path##*/}
    blog_content=()
    echo "  >>> Parsing File: [$blog] ..."
    while read line
    do
      blog_content+=("$line")
    done < "$blog_path"

    blog_offset=0
    export blog_date=""
    export blog_header=""
    if [ -z "${blog_content[0]}" ]; then
      blog_offset=1
    elif [ ! -z "${blog_content[1]}" ]; then
      blog_offset=3
      export blog_date="${blog_content[0]}"
      export blog_header="${blog_content[1]}"
    else
      blog_offset=2
      export blog_date="${blog_content[0]}"
    fi
    blog_text=""
    for ((i=${blog_offset}; i<=${#blog_content[@]}; i++))
    do
      if [ $blog_offset == 1 ]; then
        export blog_text+=""${blog_content[$i]}"</br>"
      elif [ $blog_offset == 2 ]; then
        export blog_text+="<p class=\"special\">"${blog_content[$i]}"</p>"
      elif [ $blog_offset == 3 ]; then
        export blog_text+="<p>"${blog_content[$i]}"</p>"
      else
        blog_formatting_error
      fi
    done
    blog_result=`envsubst < "$template/blog.ini"` 
    blog_data="$blog_result $blog_data"
  done

  echo "Page: [$page]"
  generate_page
done

exit 0
