class Point {
  x: number;
  y: number;
}
class Area {
  x: Point;
}
 
export default function helloWorld() {
  const pt = new Area();  
  pt.x = new Point();
  console.log("Hello, world!");
}