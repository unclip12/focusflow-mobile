import { useEffect, useRef } from "react";

export function AuroraBackground() {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    let animationId: number;
    let time = 0;

    const resize = () => {
      canvas.width = window.innerWidth;
      canvas.height = window.innerHeight;
    };
    resize();
    window.addEventListener("resize", resize);

    const blobs = [
      { x: 0.3, y: 0.2, r: 300, color: [99, 102, 241], speed: 0.0003, phase: 0 },
      { x: 0.7, y: 0.4, r: 250, color: [129, 140, 248], speed: 0.0004, phase: 2 },
      { x: 0.5, y: 0.7, r: 280, color: [67, 56, 202], speed: 0.00035, phase: 4 },
      { x: 0.2, y: 0.8, r: 220, color: [139, 92, 246], speed: 0.00045, phase: 1 },
      { x: 0.8, y: 0.15, r: 200, color: [79, 70, 229], speed: 0.0005, phase: 3 },
    ];

    const draw = () => {
      time++;
      ctx.fillStyle = "#0E0E1A";
      ctx.fillRect(0, 0, canvas.width, canvas.height);

      blobs.forEach((blob) => {
        const cx = canvas.width * (blob.x + 0.15 * Math.sin(time * blob.speed + blob.phase));
        const cy = canvas.height * (blob.y + 0.1 * Math.cos(time * blob.speed * 1.3 + blob.phase));
        const gradient = ctx.createRadialGradient(cx, cy, 0, cx, cy, blob.r * (canvas.width / 400));
        gradient.addColorStop(0, `rgba(${blob.color.join(",")}, 0.35)`);
        gradient.addColorStop(0.5, `rgba(${blob.color.join(",")}, 0.12)`);
        gradient.addColorStop(1, `rgba(${blob.color.join(",")}, 0)`);
        ctx.fillStyle = gradient;
        ctx.fillRect(0, 0, canvas.width, canvas.height);
      });

      animationId = requestAnimationFrame(draw);
    };
    draw();

    return () => {
      cancelAnimationFrame(animationId);
      window.removeEventListener("resize", resize);
    };
  }, []);

  return (
    <canvas
      ref={canvasRef}
      className="fixed inset-0 w-full h-full"
      style={{ zIndex: 0 }}
    />
  );
}
