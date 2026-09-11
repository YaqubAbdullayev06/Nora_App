import { useState, useEffect } from 'react'
import LoaderOne from '@/components/ui/loader-one'
import AnimatedText from '@/components/ui/animated-text'

function App() {
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    // Simulate loading for 3 seconds
    const timer = setTimeout(() => {
      setIsLoading(false)
    }, 3000)

    return () => clearTimeout(timer)
  }, [])

  if (isLoading) {
    return (
      <div className="flex flex-col items-center justify-center min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900">
        <div className="flex flex-col items-center gap-6">
          <AnimatedText
            text="Nora"
            className="text-5xl font-bold text-white mb-2"
            animationType="letters"
            staggerDelay={0.1}
            duration={0.8}
          />
          <LoaderOne />
          <p className="text-white/60 text-sm mt-4">Loading...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900">
      <div className="text-center">
        <AnimatedText
          text="Welcome to Nora"
          className="text-4xl font-bold text-white mb-4"
          animationType="words"
          staggerDelay={0.12}
          duration={0.6}
        />
        <AnimatedText
          text="The app has finished loading."
          className="text-lg text-white/60 mb-8"
          animationType="words"
          delay={0.5}
          staggerDelay={0.08}
          duration={0.5}
        />
        <button
          onClick={() => setIsLoading(true)}
          className="px-6 py-2 bg-blue-500 hover:bg-blue-600 text-white rounded-lg transition-colors"
        >
          Show Loader Again
        </button>
      </div>
    </div>
  )
}

export default App
