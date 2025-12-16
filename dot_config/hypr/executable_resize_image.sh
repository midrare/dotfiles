#!/bin/sh

calc_greatest_common_denominator() {
  _cagrcode_a="${1:?expected width}"
  _cagrcode_b="${2:?expected height}"

  while [ "${_cagrcode_b}" -ne 0 ]; do
    _cagrcode_t="${_cagrcode_b}"
    _cagrcode_b="$((_cagrcode_a % _cagrcode_b))"
    _cagrcode_a="${_cagrcode_t}"
  done

  echo "${_cagrcode_a}"
  unset _cagrcode_a _cagrcode_b _cagrcode_t
}

read_image_origin_json() {
  _reimjs_json="${1:?expected json file path}"

  _reimjs_origin_x="$(jq -r '.origin_x' "${_reimjs_json}")"
  _reimjs_origin_x="${_reimjs_origin_x#null}"

  _reimjs_origin_y="$(jq -r '.origin_y' "${_reimjs_json}")"
  _reimjs_origin_y="${_reimjs_origin_y#null}"

  echo ${_reimjs_origin_x} ${_reimjs_origin_y}
  unset _reimjs_origin_x _reimjs_origin_y
}

read_image_bounds_json() {
  _reimjs_json="${1:?expected json file path}"

  _reimjs_bounds_x="$(jq -r '.bounds_x' "${_reimjs_json}")"
  _reimjs_bounds_x="${_reimjs_bounds_x#null}"

  _reimjs_bounds_y="$(jq -r '.bounds_y' "${_reimjs_json}")"
  _reimjs_bounds_y="${_reimjs_bounds_y#null}"

  _reimjs_bounds_w="$(jq -r '.bounds_width' "${_reimjs_json}")"
  _reimjs_bounds_w="${_reimjs_bounds_w#null}"

  _reimjs_bounds_h="$(jq -r '.bounds_height' "${_reimjs_json}")"
  _reimjs_bounds_h="${_reimjs_bounds_h#null}"

  echo ${_reimjs_bounds_x} ${_reimjs_bounds_y} \
    ${_reimjs_bounds_w} ${_reimjs_bounds_h}
  unset _reimjs_bounds_x _reimjs_bounds_y \
    _reimjs_bounds_w _reimjs_bounds_h
}

calc_crop_aspect_ratio_bounds() {
  _cacrsi_bx="${1:?expected bounds x}"
  _cacrsi_by="${2:?expected bounds y}"
  _cacrsi_bw="${3:?expected bounds width}"
  _cacrsi_bh="${4:?expected bounds height}"
  _cacrsi_ar="${5:?expected aspect ratio}"

  _cacrsi_orig_ar="$(bc -l <<<"scale=10; ${_cacrsi_bw} / ${_cacrsi_bh}")"
  _cacrsi_is_wider="$(bc -l <<<"${_cacrsi_orig_ar} > ${_cacrsi_ar}")"

  if [ "${_cacrsi_is_wider}" -gt 0 ]; then
    _cacrsi_cx="${_cacrsi_bx%.*}"
    _cacrsi_cy="${_cacrsi_by%.*}"
    _cacrsi_cw="$(bc -l <<<"scale=10; ${_cacrsi_bh} * ${_cacrsi_ar}")"
    _cacrsi_cw="${_cacrsi_cw%.*}"
    _cacrsi_ch="${_cacrsi_bh%.*}"
    if [ $(bc -l <<<"${_cacrsi_cw} > ${_cacrsi_bw}") -gt 0 ]; then
      _cacrsi_cw="${_cacrsi_bw%.*}"
    fi
  else
    _cacrsi_cx="${_cacrsi_bx%.*}"
    _cacrsi_cy="${_cacrsi_by%.*}"
    _cacrsi_cw="${_cacrsi_bw%.*}"
    _cacrsi_ch="$(bc -l <<<"scale=10; ${_cacrsi_bw} / ${_cacrsi_ar}")"
    _cacrsi_ch="${_cacrsi_ch%.*}"
    if [ $(bc -l <<<"${_cacrsi_ch} > ${_cacrsi_bh}") -gt 0 ]; then
      _cacrsi_ch="${_cacrsi_bh%.*}"
    fi
  fi

  echo "${_cacrsi_cx} ${_cacrsi_cy} ${_cacrsi_cw} ${_cacrsi_ch}"
  unset _cacrsi_bx _cacrsi_by \
    _cacrsi_bw _cacrsi_bh \
    _cacrsi_cx _cacrsi_cy \
    _cacrsi_cw _cacrsi_ch \
    _cacrsi_ar _cacrsi_orig_ar \
    _cacrsi_is_wider
}


clamp_point_to_bounds() {
  _cltobo_ox="${1:?expected origin x}"
  _cltobo_oy="${2:?expected origin y}"
  _cltobo_bx="${3:?expected bounds x}"
  _cltobo_by="${4:?expected bounds y}"
  _cltobo_bw="${5:?expected bounds width}"
  _cltobo_bh="${6:?expected bounds height}"

  _cltobo_x=$((_cltobo_ox - _cltobo_bx))
  _cltobo_y=$((_cltobo_oy - _cltobo_by))

  if [ "${_cltobo_x}" -lt 0 ]; then
    _cltobo_x=0
  fi
  if [ "${_cltobo_y}" -lt 0 ]; then
    _cltobo_y=0
  fi

  _cltobo_max_x=$((_cltobo_bw - crop_w))
  if [ "${_cltobo_max_x}" -lt 0 ]; then
    _cltobo_max_x=0
  fi

  _cltobo_max_y=$((_cltobo_bh - crop_h))
  if [ "${_cltobo_max_y}" -lt 0 ]; then
    _cltobo_max_y=0
  fi

  if [ "${_cltobo_x}" -gt "${_cltobo_max_x}" ]; then
    _cltobo_x="${_cltobo_max_x}"
  fi
  if [ "${_cltobo_y}" -gt "${_cltobo_max_y}" ]; then
    _cltobo_y="${_cltobo_max_y}"
  fi

  echo "${_cltobo_x} ${_cltobo_y}"
  unset _cltobo_x _cltobo_y
}


IMG_FILE="${1:?expected image file path}"
DEST_FILE="${2:?expected destination file path}"
JSON_FILE="${3:?expected json file path}"
TARGET_SIZE="${4:?expected target size}"

width="${TARGET_SIZE%%x*}"
height="${TARGET_SIZE##*x}"

read pox poy < <(read_image_origin_json "${JSON_FILE}")
read pbx pby pbw pbh < <(read_image_bounds_json "${JSON_FILE}")
read img_width img_height < <(magick identify -format "%w %h" "${IMG_FILE}")


echo "${pbx} ${pby} ${pbw} ${pbh}"

ox="$(bc -l <<<"scale=10; ${pox:-0.5} * ${img_width}")"
oy="$(bc -l <<<"scale=10; ${poy:-0.5} * ${img_height}")"

read cx cy cw ch < <(
  calc_crop_aspect_ratio_bounds \
    "$(bc -l <<<"scale=10; ${pbx:-1} * ${img_width}")" \
    "$(bc -l <<<"scale=10; ${pby:-1} * ${img_height}")" \
    "$(bc -l <<<"scale=10; ${pbw:-1} * ${img_width}")" \
    "$(bc -l <<<"scale=10; ${pbh:-1} * ${img_height}")" \
    "$(bc -l <<<"scale=10; ${width} / ${height}")"
)

read cox coy < <(
  clamp_point_to_bounds \
    "${ox}" "${oy}" \
    "${cx}" "${cy}" \
    "${cw}" "${ch}"
)

echo "Image path: ${IMG_FILE}"
echo "JSON path: ${JSON_FILE}"
echo "Image size: ${img_width}x${img_height}"
echo "Target size: ${width}x${height}"
echo "Origin: (${ox}, ${oy})"
echo "Crop: (${cx}, ${cy}) ${cw}x${ch}"


if [ "${img_width}" -lt "${width}" ]; then
  echo "Warning: image width ${img_width} is less than target width ${width}" >&2
fi

if [ "${img_height}" -lt "${height}" ]; then
  echo "Warning: image height ${img_height} is less than target height ${height}" >&2
fi

mkdir -p  "$(dirname "${DEST_FILE}")"
magick "${IMG_FILE}" \
  -quality 100 \
  -crop "${cw}x${ch}+${cx}+${cy}" +repage \
  -resize "${width}x${height}" +repage \
  "${DEST_FILE}"

