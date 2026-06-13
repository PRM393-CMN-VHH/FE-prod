String flowerColorLabel(String color) {
  final normalized = _normalize(color);
  switch (normalized) {
    case 'red':
    case 'do':
      return 'Đỏ';
    case 'pink':
    case 'hong':
      return 'Hồng';
    case 'white':
    case 'trang':
      return 'Trắng';
    case 'yellow':
    case 'vang':
      return 'Vàng';
    case 'purple':
    case 'tim':
      return 'Tím';
    case 'orange':
    case 'cam':
      return 'Cam';
    case 'blue':
    case 'xanh duong':
      return 'Xanh dương';
    case 'green':
    case 'xanh la':
    case 'xanh la cay':
      return 'Xanh lá';
    case 'cream':
    case 'kem':
      return 'Kem';
    case 'mixed':
    case 'mix':
    case 'nhieu mau':
      return 'Nhiều màu';
    default:
      return color.trim();
  }
}

String flowerColorKey(String color) {
  return flowerColorLabel(color).toLowerCase();
}

String _normalize(String value) {
  var text = value.trim().toLowerCase();
  const replacements = {
    'à': 'a',
    'á': 'a',
    'ạ': 'a',
    'ả': 'a',
    'ã': 'a',
    'â': 'a',
    'ầ': 'a',
    'ấ': 'a',
    'ậ': 'a',
    'ẩ': 'a',
    'ẫ': 'a',
    'ă': 'a',
    'ằ': 'a',
    'ắ': 'a',
    'ặ': 'a',
    'ẳ': 'a',
    'ẵ': 'a',
    'è': 'e',
    'é': 'e',
    'ẹ': 'e',
    'ẻ': 'e',
    'ẽ': 'e',
    'ê': 'e',
    'ề': 'e',
    'ế': 'e',
    'ệ': 'e',
    'ể': 'e',
    'ễ': 'e',
    'ì': 'i',
    'í': 'i',
    'ị': 'i',
    'ỉ': 'i',
    'ĩ': 'i',
    'ò': 'o',
    'ó': 'o',
    'ọ': 'o',
    'ỏ': 'o',
    'õ': 'o',
    'ô': 'o',
    'ồ': 'o',
    'ố': 'o',
    'ộ': 'o',
    'ổ': 'o',
    'ỗ': 'o',
    'ơ': 'o',
    'ờ': 'o',
    'ớ': 'o',
    'ợ': 'o',
    'ở': 'o',
    'ỡ': 'o',
    'ù': 'u',
    'ú': 'u',
    'ụ': 'u',
    'ủ': 'u',
    'ũ': 'u',
    'ư': 'u',
    'ừ': 'u',
    'ứ': 'u',
    'ự': 'u',
    'ử': 'u',
    'ữ': 'u',
    'ỳ': 'y',
    'ý': 'y',
    'ỵ': 'y',
    'ỷ': 'y',
    'ỹ': 'y',
    'đ': 'd',
  };
  replacements.forEach((from, to) {
    text = text.replaceAll(from, to);
  });
  return text.replaceAll(RegExp(r'\s+'), ' ');
}
